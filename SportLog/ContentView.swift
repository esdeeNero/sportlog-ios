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

struct ContentView: View {
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

