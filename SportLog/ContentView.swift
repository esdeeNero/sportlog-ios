import SwiftUI

private enum SportStyle {
    static let ink = Color(red: 0.08, green: 0.12, blue: 0.10)
    static let lime = Color(red: 0.78, green: 0.96, blue: 0.29)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.94)
    static let muted = Color(red: 0.48, green: 0.52, blue: 0.49)
}

private struct Workout: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let duration: String
    let symbol: String
    var isDone = false
}

struct DashboardView: View {
    @State private var testCount = 0
    @State private var workouts = [
        Workout(title: "Силовая тренировка", detail: "Верх тела · 6 упражнений", duration: "45 мин", symbol: "dumbbell.fill"),
        Workout(title: "Лёгкий бег", detail: "Восстановительный темп", duration: "30 мин", symbol: "figure.run"),
        Workout(title: "Растяжка", detail: "Мобильность и восстановление", duration: "15 мин", symbol: "figure.cooldown", isDone: true)
    ]

    private var completedCount: Int { workouts.filter(\.isDone).count }

    var body: some View {
        ZStack {
            SportStyle.canvas.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    weeklyCard
                    testCounterCard
                    MediaSection()
                    weekStrip
                    workoutSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("СРЕДА, 11 НОЯБРЯ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(SportStyle.muted)
                Text("Твой ритм.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(SportStyle.ink)
            }
            Spacer()
            Image(systemName: "figure.run")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(SportStyle.ink)
                .frame(width: 48, height: 48)
                .background(SportStyle.lime, in: Circle())
        }
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("ЭТА НЕДЕЛЯ", systemImage: "bolt.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                Spacer()
                Text("ЦЕЛЬ 4 ТРЕНИРОВКИ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.63))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(completedCount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                Text("из 4")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(SportStyle.lime)
                    .padding(14)
                    .background(.white.opacity(0.09), in: Circle())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule().fill(SportStyle.lime).frame(width: proxy.size.width * min(CGFloat(completedCount) / 4, 1))
                }
            }
            .frame(height: 8)
            Text("Отличный темп — продолжай в том же духе")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(SportStyle.ink, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var testCounterCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Проверка на iPhone")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(SportStyle.ink)
                Text("Нажми кнопку — счётчик изменится")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(SportStyle.muted)
            }
            Spacer(minLength: 4)
            Button {
                testCount += 1
            } label: {
                Label("\(testCount)", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(SportStyle.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(SportStyle.lime, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"], 10...16)), id: \.1) { day, date in
                let selected = date == 11
                VStack(spacing: 10) {
                    Text(day).font(.system(size: 9, weight: .bold, design: .rounded)).tracking(0.7)
                    Text("\(date)").font(.system(size: 14, weight: .bold, design: .rounded))
                    Circle().fill(date == 10 ? SportStyle.lime : .clear).frame(width: 5, height: 5)
                }
                .foregroundStyle(selected ? SportStyle.ink : SportStyle.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? .white : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("План на сегодня")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(SportStyle.ink)
                Spacer()
                Text("\(workouts.count) ЗАНЯТИЯ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(SportStyle.muted)
            }
            ForEach(workouts.indices, id: \.self) { index in
                workoutRow(at: index)
            }
        }
    }

    private func workoutRow(at index: Int) -> some View {
        let workout = workouts[index]
        return Button {
            workouts[index].isDone.toggle()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: workout.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SportStyle.ink)
                    .frame(width: 48, height: 48)
                    .background(SportStyle.canvas, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    Text(workout.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SportStyle.ink)
                    Text(workout.detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SportStyle.muted)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 9) {
                    Image(systemName: workout.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(workout.isDone ? Color.green : SportStyle.muted.opacity(0.55))
                    Text(workout.duration)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SportStyle.muted)
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(workout.title), \(workout.isDone ? "выполнено" : "не выполнено"). Нажми, чтобы изменить статус")
    }
}

#Preview {
    ContentView()
}


struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Главная", systemImage: "house.fill") }
            TrainingLibrary().tabItem { Label("Тренировки", systemImage: "play.rectangle.fill") }
            TrainingCalendar().tabItem { Label("Календарь", systemImage: "calendar") }
            PalmCalculator().tabItem { Label("Питание", systemImage: "hand.raised.fill") }
        }.tint(SportStyle.ink)
    }
}

private struct MediaSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ZStack { SportStyle.ink; Image(systemName: "figure.strengthtraining.traditional").font(.largeTitle).foregroundStyle(SportStyle.lime) }
            }.frame(height: 180).clipped().clipShape(RoundedRectangle(cornerRadius: 22))
            Text("Двигайся в своём ритме").font(.title2.bold())
            Link(destination: URL(string: "https://www.youtube.com/watch?v=b-i4N6cVzec")!) {
                Label("Видеотренировка · Fitness Blender", systemImage: "play.circle.fill")
            }
            HStack {
                Link("♫ Spotify", destination: URL(string: "https://open.spotify.com/")!)
                Spacer()
                Link("♫ Яндекс Музыка", destination: URL(string: "https://music.yandex.ru/")!)
            }.font(.headline)
        }.padding().background(.white, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct TrainingLibrary: View {
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

private struct TrainingCalendar: View {
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

private struct PalmCalculator: View {
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
