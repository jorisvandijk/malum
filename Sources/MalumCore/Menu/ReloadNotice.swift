/// The notification Reload in the menu shows when it's done: that it worked, or the first error
/// it ran into and how many more there were. Warnings don't count as failing.
public struct ReloadNotice: Equatable, Sendable {
    /// The notification's title.
    public let title: String
    /// The line under the title.
    public let body: String

    /// The notice for a reload that reported `messages` and left `running` modules switched on.
    public init(messages: [Message], running: Int) {
        let errors = messages.filter { $0.level == .error }
        guard let first = errors.first else {
            title = Self.reloaded
            body = Self.restarted(running)
            return
        }
        title = Self.failed
        body = Self.problem(first.text.description, more: errors.count - 1)
    }
}
