/// One tagged line for the user, such as `[error] unknown command: foo`.
///
/// Every message is worded in this folder, from the shapes in `Message+Shapes.swift`, and the
/// rest of the code asks for one by name, such as `.installed(label, name)`.
public struct Message: Equatable, Sendable {
    /// How serious it is.
    public let level: Level
    /// What happened.
    public let text: MessageText

    /// Creates a message with its level and text.
    public init(_ level: Level, _ text: MessageText) {
        self.level = level
        self.text = text
    }
}

// MARK: - CustomStringConvertible

extension Message: CustomStringConvertible {
    /// The message with its tag in front.
    public var description: String { "[\(level.rawValue)] \(text)" }
}
