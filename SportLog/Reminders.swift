import SwiftUI
import UserNotifications

struct ReminderSettings: View {
    @AppStorage("sportlog.reminders.enabled") private var enabled = false
    @AppStorage("sportlog.reminders.food") private var food = 13
    @AppStorage("sportlog.reminders.workout") private var workout = 18
    @AppStorage("sportlog.reminders.sleep") private var sleep = 23
    @State private var message = ""
    @State private var saving = false
    private let ids = ["sportlog.food", "sportlog.workout", "sportlog.sleep"]
    var body: some View {
        Form {
            Section("Ежедневный ритм") {
                Toggle("Напоминания", isOn: $enabled)
                hourPicker("Приём пищи", value: $food)
                hourPicker("Тренировка", value: $workout)
                hourPicker("Подготовка ко сну", value: $sleep)
            }
            Section {
                Button(saving ? "Сохраняем…" : "Сохранить расписание") { Task { await save() } }.disabled(saving)
                Text(message.isEmpty ? "Уведомления приходят каждый день по местному времени. Изменения применяются после сохранения." : message).font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Напоминания")
    }
    private func hourPicker(_ title: String, value: Binding<Int>) -> some View {
        Picker(title, selection: value) { ForEach(0..<24) { Text(String(format: "%02d:00", $0)).tag($0) } }
    }
    private func save() async {
        saving = true
        defer { saving = false }
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: ids)
            message = "Напоминания отключены"; return
        }
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else {
                enabled = false
                center.removePendingNotificationRequests(withIdentifiers: ids)
                message = "Уведомления запрещены. Разрешите их в настройках iPhone."; return
            }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            let entries = [(ids[0], food, "Время поесть", "Сделайте паузу и запишите порции в SportLog."), (ids[1], workout, "Время движения", "Посмотрите план тренировки или выйдите на прогулку."), (ids[2], sleep, "Пора замедлиться", "Завершите дела и подготовьтесь ко сну.")]
            for (id, hour, title, body) in entries {
                let content = UNMutableNotificationContent(); content.title = title; content.body = body; content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: 0), repeats: true)
                try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
            message = "Три ежедневных напоминания включены"
        } catch { message = "Не удалось сохранить: \(error.localizedDescription)" }
    }
}
