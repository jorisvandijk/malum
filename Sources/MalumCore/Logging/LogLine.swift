/// One of Malum's entries in the unified log, as `malum log` shows it.
public struct LogLine: Equatable, Sendable {
    /// The time of day, such as `00:12:01`.
    public let time: String
    /// The part of Malum that wrote it: `app` or a module's id.
    public let category: String
    /// What it says, with its tag, such as `[info] loaded <private>`.
    public let text: String
}
