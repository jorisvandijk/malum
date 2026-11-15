import UserNotifications

/// Shows notifications from Malum through macOS's Notification Center. The first one asks the
/// user to allow them.
@MainActor
public final class Notifier {
    /// Creates the notifier.
    public init() {}

    /// Shows `title` with `body` under it, and says whether macOS let it. False when the user
    /// turned Malum's notifications off, or macOS couldn't ask.
    public func show(title: String, body: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            guard try await center.requestAuthorization(options: [.alert]) else { return false }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            try await center.add(UNNotificationRequest(identifier: title, content: content, trigger: nil))
        } catch {
            return false
        }
        return true
    }
}
