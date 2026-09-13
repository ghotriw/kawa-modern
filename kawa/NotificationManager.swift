import Cocoa
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notify(source: InputSourceItem) {
        let content = UNMutableNotificationContent()
        content.title = source.name
        content.body = "Switched input source"

        let request = UNNotificationRequest(
            identifier: "kawa_layout_switch",
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }
}
