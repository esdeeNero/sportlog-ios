import SwiftUI

struct TrainingLibrary: View {
    private let videos = [
        ("Силовая без оборудования", "Умеренная нагрузка, всё тело", "b-i4N6cVzec"),
        ("Сила и кардио", "Всё тело, упражнения без повторов", "KfEOuV34WRc")
    ]
    var body: some View {
        NavigationStack {
            List {
                ForEach(videos, id: \.2) { video in
                    Link(destination: URL(string: "https://www.youtube.com/watch?v=\(video.2)")!) {
                        VStack(alignment: .leading, spacing: 10) {
                            AsyncImage(url: URL(string: "https://i.ytimg.com/vi/\(video.2)/hqdefault.jpg")) { image in
                                image.resizable().scaledToFit()
                            } placeholder: { ProgressView().frame(height: 120) }
                            Label(video.0, systemImage: "play.circle.fill").font(.headline)
                            Text(video.1).font(.subheadline)
                            Text("Fitness Blender · Смотреть на YouTube ↗").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }
                }
            }.navigationTitle("Тренировки")
        }
    }
}

struct TrainingCalendar: View {
    @State private var date = Date()
    @AppStorage("sportlog.calendar.notes") private var storedNotes = "{}"
    private let calendar = Calendar.current
    private var range: ClosedRange<Date> {
        calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!...calendar.date(from: DateComponents(year: 2028, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
    }
    private var key: String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
    private var notes: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: Data(storedNotes.utf8))) ?? [:]
    }
    private var note: Binding<String> {
        Binding(get: { notes[key] ?? "" }, set: { value in
            var updated = notes
            updated[key] = value.isEmpty ? nil : value
            if let data = try? JSONEncoder().encode(updated), let text = String(data: data, encoding: .utf8) { storedNotes = text }
        })
    }
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("День тренировки", selection: $date, in: range, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Section(date.formatted(date: .complete, time: .omitted)) {
                    TextField("План, упражнения или результат", text: note, axis: .vertical).lineLimit(3...8)
                    Text("Заметки сохраняются автоматически на устройстве.").font(.caption).foregroundStyle(.secondary)
                }
                Section { Text("Календарь доступен до 31 декабря 2028 года.") }
            }.navigationTitle("Мой календарь")
        }.environment(\.locale, Locale(identifier: "ru_RU"))
    }
}

struct PalmCalculator: View {
    @AppStorage("sportlog.palms") private var palms = 0
    @AppStorage("sportlog.cups") private var cups = 0
    @AppStorage("sportlog.thumbs") private var thumbs = 0
    @AppStorage("sportlog.fists") private var fists = 0
    var body: some View {
        NavigationStack {
            Form {
                Section("Порции за приём пищи") {
                    Stepper("Ладонь белка: \(palms)", value: $palms, in: 0...20)
                    Stepper("Горсть углеводов: \(cups)", value: $cups, in: 0...20)
                    Stepper("Большой палец жиров: \(thumbs)", value: $thumbs, in: 0...20)
                    Stepper("Кулак овощей: \(fists)", value: $fists, in: 0...20)
                }
                Section("Приблизительное БЖУ") {
                    Text("Белки: ≈\(palms * 25) г")
                    Text("Жиры: ≈\(thumbs * 10) г")
                    Text("Углеводы: ≈\(cups * 25) г")
                    Text("Упрощённая оценка основных макронутриентов: ладонь ≈25 г белка, горсть ≈25 г углеводов, большой палец ≈10 г жиров. Размер руки и состав еды меняют результат; сопутствующие нутриенты и овощи в итог не включены.").font(.caption).foregroundStyle(.secondary)
                    Link("О методе · Precision Nutrition", destination: URL(string: "https://www.precisionnutrition.com/hand-portion-math-to-track-macros")!)
                }
                Button("Сбросить порции", role: .destructive) { palms = 0; cups = 0; thumbs = 0; fists = 0 }
            }.navigationTitle("Метод ладони")
        }
    }
}
