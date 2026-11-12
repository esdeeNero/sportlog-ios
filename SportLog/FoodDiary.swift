import SwiftUI
import PhotosUI
import AVFoundation
import Vision

nonisolated struct FoodPortion: Identifiable, Codable {
    var id = UUID()
    var name: String
    var grams: Double = 100
    var kcal100: Double
    var protein100: Double
    var fat100: Double
    var carbs100: Double
    var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && grams.isFinite && grams > 0 && grams <= 10000 && [kcal100, protein100, fat100, carbs100].allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 1000 }
    }
    var calories: Double { grams * kcal100 / 100 }
    var protein: Double { grams * protein100 / 100 }
    var fat: Double { grams * fat100 / 100 }
    var carbs: Double { grams * carbs100 / 100 }
}
nonisolated struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var meal: String
    var portions: [FoodPortion]
    var calories: Double { portions.reduce(0) { $0 + $1.calories } }
}
nonisolated struct FoodTemplate: Identifiable {
    let id: String
    let labels: [String]
    let portion: FoodPortion
    static let all: [FoodTemplate] = [
        .init(id: "apple", labels: ["apple"], portion: .init(name: "Яблоко", kcal100: 52, protein100: 0.3, fat100: 0.2, carbs100: 14)),
        .init(id: "banana", labels: ["banana"], portion: .init(name: "Банан", kcal100: 89, protein100: 1.1, fat100: 0.3, carbs100: 23)),
        .init(id: "orange", labels: ["orange", "citrus_fruit"], portion: .init(name: "Апельсин", kcal100: 47, protein100: 0.9, fat100: 0.1, carbs100: 12)),
        .init(id: "pizza", labels: ["pizza"], portion: .init(name: "Пицца, усреднённо", kcal100: 266, protein100: 11, fat100: 10, carbs100: 33)),
        .init(id: "rice", labels: ["rice"], portion: .init(name: "Рис отварной", kcal100: 130, protein100: 2.7, fat100: 0.3, carbs100: 28)),
        .init(id: "pasta", labels: ["pasta", "spaghetti", "noodle", "noodles"], portion: .init(name: "Макароны отварные без соуса", kcal100: 158, protein100: 5.8, fat100: 0.9, carbs100: 31)),
        .init(id: "bread", labels: ["bread", "toast"], portion: .init(name: "Хлеб пшеничный", kcal100: 265, protein100: 9, fat100: 3.2, carbs100: 49)),
        .init(id: "egg", labels: ["egg", "fried_egg", "omelet", "omelette"], portion: .init(name: "Яйцо, без масла", kcal100: 155, protein100: 13, fat100: 11, carbs100: 1.1)),
        .init(id: "salad", labels: ["salad"], portion: .init(name: "Овощной салат без заправки", kcal100: 25, protein100: 1.2, fat100: 0.2, carbs100: 4.5)),
        .init(id: "broccoli", labels: ["broccoli"], portion: .init(name: "Брокколи", kcal100: 34, protein100: 2.8, fat100: 0.4, carbs100: 7)),
        .init(id: "chicken", labels: ["cooked_chicken", "roast_chicken", "fried_chicken"], portion: .init(name: "Курица готовая, уточните часть и масло", kcal100: 200, protein100: 27, fat100: 10, carbs100: 0)),
        .init(id: "salmon", labels: ["salmon"], portion: .init(name: "Лосось готовый", kcal100: 206, protein100: 22, fat100: 12, carbs100: 0))
    ]
}
nonisolated struct FoodSuggestion: Identifiable {
    let template: FoodTemplate
    let confidence: Float
    var id: String { template.id }
}
// Generic Vision labels identify candidate foods, not portion size or ingredients.
actor FoodPhotoRecognizer {
    func recognize(_ data: Data) throws -> [FoodSuggestion] {
        let request = VNClassifyImageRequest()
        try VNImageRequestHandler(data: data, options: [:]).perform([request])
        let observations = request.results ?? []
        return FoodTemplate.all.compactMap { template in
            let confidence = observations.filter { template.labels.contains($0.identifier.lowercased().replacingOccurrences(of: " ", with: "_")) }.map(\.confidence).max() ?? 0
            return confidence >= 0.25 ? FoodSuggestion(template: template, confidence: confidence) : nil
        }.sorted { $0.confidence > $1.confidence }.prefix(4).map { $0 }
    }
}

struct FoodDiaryView: View {
    @AppStorage("sportlog.food.entries") private var stored = "[]"
    @State private var editing: FoodEntry?
    @State private var showNew = false
    @State private var error = ""
    private var entries: [FoodEntry] { (try? JSONDecoder().decode([FoodEntry].self, from: Data(stored.utf8))) ?? [] }
    private var today: [FoodEntry] { entries.filter { Calendar.current.isDateInToday($0.date) } }
    var body: some View {
        List {
            Section("Сегодня") {
                Text("≈\(Int(today.reduce(0) { $0 + $1.calories })) ккал").font(.largeTitle.bold())
                Text("Б \(total(\.protein)) г · Ж \(total(\.fat)) г · У \(total(\.carbs)) г").foregroundStyle(.secondary)
                Button { showNew = true } label: { Label("Сфотографировать / добавить еду", systemImage: "camera.fill") }
            }
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            Section("Дневник · нажми для исправления") {
                if entries.isEmpty { Text("Сохранённые приёмы пищи появятся здесь").foregroundStyle(.secondary) }
                ForEach(entries.sorted { $0.date > $1.date }) { entry in
                    Button { editing = entry } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(entry.meal) · ≈\(Int(entry.calories)) ккал").font(.headline)
                            Text(entry.portions.map(\.name).joined(separator: ", ")).font(.subheadline)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain).swipeActions { Button("Удалить", role: .destructive) { persist(entries.filter { $0.id != entry.id }) } }
                }
            }
        }.navigationTitle("Фото еды")
            .sheet(isPresented: $showNew) { NavigationStack { FoodEditor(entry: FoodEntry(meal: "Обед", portions: [])) { save($0) } } }
            .sheet(item: $editing) { entry in NavigationStack { FoodEditor(entry: entry) { save($0) } } }
    }
    private func total(_ key: KeyPath<FoodPortion, Double>) -> Int { Int(today.flatMap(\.portions).reduce(0) { $0 + $1[keyPath: key] }) }
    private func persist(_ value: [FoodEntry]) {
        do { stored = String(decoding: try JSONEncoder().encode(value), as: UTF8.self); error = "" }
        catch { self.error = "Не удалось сохранить дневник" }
    }
    private func save(_ entry: FoodEntry) {
        var updated = entries
        if let index = updated.firstIndex(where: { $0.id == entry.id }) { updated[index] = entry } else { updated.append(entry) }
        persist(updated)
    }
}
struct FoodEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var entry: FoodEntry
    let onSave: (FoodEntry) -> Void
    @State private var photo: UIImage?
    @State private var picker: PhotosPickerItem?
    @State private var camera = false
    @State private var busy = false
    @State private var message = ""
    @State private var suggestions: [FoodSuggestion] = []
    @State private var task: Task<Void, Never>?
    @State private var generation = UUID()
    private let recognizer = FoodPhotoRecognizer()
    var body: some View {
        Form {
            Section {
                if let photo { Image(uiImage: photo).resizable().scaledToFit().frame(maxHeight: 230) }
                HStack {
                    Button { Task { await openCamera() } } label: { Label("Камера", systemImage: "camera") }.disabled(busy)
                    Spacer()
                    PhotosPicker(selection: $picker, matching: .images) { Label("Фото", systemImage: "photo") }.disabled(busy)
                }
                Text("Распознавание на iPhone. Фото никуда не отправляется и не сохраняется в дневнике.").font(.caption).foregroundStyle(.secondary)
                if busy { ProgressView("Распознаём еду…") }
                if !message.isEmpty { Text(message).font(.subheadline) }
            }
            if !suggestions.isEmpty {
                Section("Предположения · выбери продукт") {
                    ForEach(suggestions) { suggestion in
                        Button("+ \(suggestion.template.portion.name)") { add(suggestion.template.portion) }
                    }
                }
            }
            Section {
                Text("Фото помогает выбрать продукт, но не измеряет вес, масло и соус. Новая порция — 100 г для примера: укажжи фактический вес и проверь состав перед сохранением.").font(.caption).foregroundStyle(.secondary)
                Picker("Приём пищи", selection: $entry.meal) { ForEach(["Завтрак", "Обед", "Ужин", "Перекус"], id: \.self) { Text($0) } }
                DatePicker("Когда", selection: $entry.date, in: ...Date())
            }
            ForEach($entry.portions) { $portion in
                Section {
                    TextField("Продукт", text: $portion.name)
                    number("Вес порции, г", value: $portion.grams)
                    DisclosureGroup("Исправить КБЖУ на 100 г") {
                        number("ккал / 100 г", value: $portion.kcal100)
                        number("Белки, г / 100 г", value: $portion.protein100)
                        number("Жиры, г / 100 г", value: $portion.fat100)
                        number("Углеводы, г / 100 г", value: $portion.carbs100)
                    }
                    Text("Порция: ≈\(portion.calories, specifier: "%.0f") ккал · Б \(portion.protein, specifier: "%.1f") · Ж \(portion.fat, specifier: "%.1f") · У \(portion.carbs, specifier: "%.1f") г").font(.caption)
                    Button("Убрать продукт", role: .destructive) { entry.portions.removeAll { $0.id == portion.id } }
                }
            }
            Section("Добавить вручную") {
                Menu("Выбрать из справочника") { ForEach(FoodTemplate.all) { template in Button(template.portion.name) { add(template.portion) } } }
                Button("Свой продукт / блюдо") { add(FoodPortion(name: "", kcal100: 0, protein100: 0, fat100: 0, carbs100: 0)) }
                Text("Справочные значения усреднены. Для точного состава введите данные с упаковки или рецепта.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Итого на приём пищи") {
                Text("≈\(entry.calories, specifier: "%.0f") ккал").font(.title2.bold())
                Text("Б \(sum(\.protein), specifier: "%.1f") · Ж \(sum(\.fat), specifier: "%.1f") · У \(sum(\.carbs), specifier: "%.1f") г")
                Button("Подтвердить и сохранить") { onSave(entry); dismiss() }.disabled(entry.portions.isEmpty || !entry.portions.allSatisfy(\.valid) || busy)
            }
        }.navigationTitle("Оценка еды").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
            .sheet(isPresented: $camera) { FoodCamera { image in camera = false; if let image { start(image) } } }
            .onChange(of: picker) { _, item in
                task?.cancel()
                let token = UUID(); generation = token; busy = true
                task = Task {
                    do {
                        guard let data = try await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { if generation == token { busy = false; message = "Фото не удалось открыть" }; return }
                        guard !Task.isCancelled, generation == token else { return }
                        await analyze(image, token: token)
                    } catch { if generation == token { busy = false; message = "Ошибка загрузки фото" } }
                }
            }
            .onDisappear { task?.cancel(); generation = UUID() }
    }
    private func sum(_ key: KeyPath<FoodPortion, Double>) -> Double { entry.portions.reduce(0) { $0 + $1[keyPath: key] } }
    private func add(_ value: FoodPortion) { var copy = value; copy.id = UUID(); entry.portions.append(copy) }
    private func number(_ label: String, value: Binding<Double>) -> some View {
        HStack { Text(label); Spacer(); TextField(label, value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
    }
    private func start(_ image: UIImage) {
        task?.cancel(); let token = UUID(); generation = token; busy = true
        task = Task { await analyze(image, token: token) }
    }
    private func analyze(_ image: UIImage, token: UUID) async {
        // Re-render to strip EXIF, normalize orientation and bound inference memory.
        let scale = min(1, 1200 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        photo = rendered; suggestions = []; message = ""
        guard let data = rendered.jpegData(compressionQuality: 0.85) else { busy = false; message = "Не удалось обработать фото"; return }
        do {
            let result = try await recognizer.recognize(data)
            guard !Task.isCancelled, generation == token else { return }
            suggestions = result
            message = result.isEmpty ? "Не удалось уверенно определить продукт. Выберите его вручную ниже." : "Есть предположения. Подтвердите продукт ниже, затем исправьте вес и БЖУ."
        } catch { if generation == token { message = "Распознавание недоступно. Можно добавить продукты вручную." } }
        if generation == token { busy = false }
    }
    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { message = "Камера недоступна. Выберите фото из галереи."; return }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if granted { camera = true } else { message = "Разрешите доступ к камере в настройках iPhone или выберите фото." }
    }
}
struct FoodCamera: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onFinish) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.sourceType = .camera; picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let finish: (UIImage?) -> Void
        init(_ finish: @escaping (UIImage?) -> Void) { self.finish = finish }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { finish(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { finish(info[.originalImage] as? UIImage) }
    }
}
