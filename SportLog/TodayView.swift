import SwiftUI
import MapKit
import Charts

enum LogStyle {
    static let background = Color(red: 0.055, green: 0.058, blue: 0.065)
    static let card = Color(red: 0.115, green: 0.12, blue: 0.13)
    static let coral = Color(red: 0.84, green: 0.48, blue: 0.38)
}
extension View {
    func logCard() -> some View { self.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(LogStyle.card, in: RoundedRectangle(cornerRadius: 28)) }
}
struct ContentView: View {
    @State private var health = HealthStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TabView {
            NavigationStack { TodayView(health: health) }.tabItem { Label("Главная", systemImage: "house.fill") }
            NavigationStack { StatisticsView(health: health) }.tabItem { Label("Статистика", systemImage: "chart.pie.fill") }
            NavigationStack { RecipesView() }.tabItem { Label("Рецепты", systemImage: "book.closed.fill") }
            NavigationStack { MoreView(health: health) }.tabItem { Label("Меню", systemImage: "square.grid.2x2.fill") }
        }.tint(LogStyle.coral).preferredColorScheme(.dark)
            .environment(\.locale, Locale(identifier: "ru_RU"))
            .task { await health.refresh() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await health.refresh() } } }
    }
}
struct TodayView: View {
    let health: HealthStore
    @AppStorage("sportlog.reminders.enabled") private var reminders = false
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Доброе утро."
        case 12..<18: return "Добрый день."
        default: return "Добрый вечер."
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("SPORTLOG").font(.system(size: 21, weight: .black, design: .rounded)).foregroundStyle(LogStyle.coral)
                    Spacer()
                    NavigationLink { TrainingCalendar() } label: { Image(systemName: "calendar").padding(12).background(.white.opacity(0.08), in: Capsule()) }
                    NavigationLink { ReminderSettings() } label: { Image(systemName: "bell.badge").padding(12).background(.white.opacity(0.08), in: Capsule()) }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide))).foregroundStyle(.secondary)
                    Text(greeting).font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Вот как проходит твой день").foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    MetricRing(value: health.steps, goal: 6000, title: "Шаги", symbol: "shoeprints.fill", color: LogStyle.coral)
                    MetricRing(value: health.energy, goal: 400, title: "ккал активности", symbol: "flame.fill", color: .cyan)
                    MetricRing(value: health.sleep, goal: 8, title: "Часов сна", symbol: "moon.fill", color: .purple)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("Твоя сводка", systemImage: "sparkles").font(.headline)
                    Text(health.steps == nil ? "Подключи Здоровье, чтобы увидеть шаги, сон и активность за сегодня." : "Сегодня ты прошёл \(Int(health.steps ?? 0)) шагов. Тренировок в Здоровье: \(health.workoutCount).")
                    Text(health.status).font(.caption).foregroundStyle(.secondary)
                    Button(health.loading ? "Обновляем…" : "Подключить / обновить Apple Health") { Task { await health.connect() } }.buttonStyle(.borderedProminent).disabled(health.loading)
                }.logCard()
                NavigationLink { FoodDiaryView() } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Сфотографировать еду", systemImage: "camera.fill").font(.title2.bold())
                        Text("Оценить калории и БЖУ · исправить · сохранить").font(.subheadline).foregroundStyle(.secondary)
                    }.logCard()
                }.buttonStyle(.plain)
                Text("Твой режим").font(.title2.bold())
                NavigationLink { ReminderSettings() } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Еда · движение · сон", systemImage: "bell.fill").font(.headline)
                        Text(reminders ? "Напоминания включены · изменить расписание →" : "Настрой напоминания под свой день →").foregroundStyle(.secondary)
                    }.logCard()
                }.buttonStyle(.plain)
                HStack {
                    Text("Порции на приём пищи").font(.headline); Spacer()
                    NavigationLink("Записать порции") { PalmCalculator() }.font(.caption)
                }
                HStack(spacing: 10) {
                    portion("Белки", "hand.raised.fill", "sportlog.palms")
                    portion("Жиры", "drop.fill", "sportlog.thumbs")
                    portion("Углеводы", "hand.draw.fill", "sportlog.cups")
                    portion("Овощи", "carrot.fill", "sportlog.fists")
                }
                NavigationLink { RouteMapView(health: health) } label: {
                    Label("Маршруты на карте", systemImage: "map.fill").font(.headline).logCard()
                }.buttonStyle(.plain)
                NavigationLink { TrainingLibrary() } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional").font(.system(size: 42)).foregroundStyle(LogStyle.coral)
                        Text("Время для себя").font(.title2.bold())
                        Text("Выбрать видеотренировку →").foregroundStyle(.secondary)
                    }.logCard()
                }.buttonStyle(.plain)
            }.padding(20)
        }.background(LogStyle.background).toolbar(.hidden, for: .navigationBar).refreshable { await health.refresh() }
    }
    private func portion(_ title: String, _ symbol: String, _ key: String) -> some View {
        NavigationLink { PalmCalculator() } label: { PortionTile(title: title, symbol: symbol, key: key) }.buttonStyle(.plain)
    }
}
struct PortionTile: View {
    let title: String
    let symbol: String
    @AppStorage private var count: Int
    init(title: String, symbol: String, key: String) { self.title = title; self.symbol = symbol; _count = AppStorage(wrappedValue: 0, key) }
    var body: some View {
        VStack(spacing: 12) { Image(systemName: symbol).font(.title2); Text("\(count)").font(.title3.bold()); Text(title).font(.caption).lineLimit(1).minimumScaleFactor(0.7) }
            .frame(maxWidth: .infinity).padding(.vertical, 20).background(LogStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
struct MetricRing: View {
    let value: Double?
    let goal: Double
    let title: String
    let symbol: String
    let color: Color
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(.white.opacity(0.07), lineWidth: 7)
                Circle().trim(from: 0, to: min(max((value ?? 0) / goal, 0), 1)).stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                VStack(spacing: 5) { Text(value.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "—").font(.system(size: 19, weight: .bold, design: .rounded)).minimumScaleFactor(0.6); Image(systemName: symbol).font(.caption).foregroundStyle(color) }.padding(10)
            }.aspectRatio(1, contentMode: .fit)
            Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity)
    }
}
struct StatisticsView: View {
    let health: HealthStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Последние 7 дней").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 20) {
                    Text("Кольца прогресса · сегодня").font(.title2.bold())
                    HStack {
                        MetricRing(value: health.steps, goal: 6000, title: "Цель 6 000 шагов", symbol: "shoeprints.fill", color: LogStyle.coral)
                        MetricRing(value: health.energy, goal: 400, title: "Цель 400 ккал", symbol: "flame.fill", color: .cyan)
                    }
                }.logCard()
                VStack(alignment: .leading, spacing: 18) {
                    Text("Шаги").font(.title2.bold())
                    if health.days.contains(where: { $0.steps != nil }) {
                        Chart(health.days) { day in
                            BarMark(x: .value("День", day.date, unit: .day), y: .value("Шаги", day.steps ?? 0)).foregroundStyle(LogStyle.coral).cornerRadius(6)
                        }.frame(height: 220)
                        Text("Пропущенные значения означают отсутствие доступных данных.").font(.caption).foregroundStyle(.secondary)
                    } else { ContentUnavailableView("Пока нет данных", systemImage: "chart.bar", description: Text("Разрешите чтение шагов из Apple Health.")) }
                    Button("Обновить Health") { Task { await health.connect() } }.disabled(health.loading)
                }.logCard()
                NavigationLink { RouteMapView(health: health) } label: { Label("Посмотреть маршруты", systemImage: "map").logCard() }.buttonStyle(.plain)
            }.padding(20)
        }.background(LogStyle.background).navigationTitle("Статистика")
    }
}
struct RouteMapView: View {
    let health: HealthStore
    @State private var selected: UUID?
    private var route: WalkingRoute? { health.routes.first(where: { $0.id == selected }) ?? health.routes.first }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Записанные маршруты за 30 дней").font(.headline)
                Text("Шаги не содержат координат. Здесь доступны маршруты, записанные Apple Watch или другим приложением в Здоровье. Фоновое отслеживание SportLog не ведёт.").font(.subheadline).foregroundStyle(.secondary)
                if let route {
                    Picker("Маршрут", selection: $selected) { ForEach(health.routes) { item in Text(item.date.formatted(date: .abbreviated, time: .shortened)).tag(Optional(item.id)) } }
                    Map { MapPolyline(coordinates: route.points).stroke(LogStyle.coral, lineWidth: 5) }.id(route.id).frame(height: 380).clipShape(RoundedRectangle(cornerRadius: 24))
                    Text(route.date.formatted(date: .complete, time: .shortened)).font(.caption)
                } else {
                    ContentUnavailableView("Маршрутов пока нет", systemImage: "map", description: Text("Запишите прогулку с GPS и разрешите доступ к маршрутам в Здоровье."))
                }
                if health.loading { ProgressView() }
                Button("Загрузить маршруты") { Task { if !health.requested { await health.connect() }; await health.loadRoutes() } }.buttonStyle(.borderedProminent).disabled(health.loading)
                Text(health.status).font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.background(LogStyle.background).navigationTitle("Карта прогулок").task { await health.loadRoutes() }
    }
}
struct MoreView: View {
    let health: HealthStore
    var body: some View {
        List {
            Section("Твой SportLog") {
                NavigationLink("Фото еды и дневник питания") { FoodDiaryView() }
                NavigationLink("Календарь до 2028 года") { TrainingCalendar() }
                NavigationLink("Видеотренировки") { TrainingLibrary() }
                NavigationLink("Питание методом ладони") { PalmCalculator() }
                NavigationLink("Напоминания") { ReminderSettings() }
                NavigationLink("Маршруты прогулок") { RouteMapView(health: health) }
            }
            Section("Музыка для движения") {
                Link("Открыть Spotify ↗", destination: URL(string: "https://open.spotify.com/")!)
                Link("Открыть Яндекс Музыку ↗", destination: URL(string: "https://music.yandex.ru/")!)
            }
            Section("Здоровье и приватность") {
                Button("Подключить Apple Health") { Task { await health.connect() } }
                Text("Данные Здоровья и маршруты обрабатываются на устройстве. SportLog не отправляет их на сервер. Права чтения можно изменить в приложении Здоровье.").font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Меню")
    }
}
