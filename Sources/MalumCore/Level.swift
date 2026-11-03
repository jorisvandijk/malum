/// How serious a message is, shown as its tag.
public enum Level: String, Sendable {
    /// Something happened as expected.
    case info
    /// Something needs attention, but Malum carries on.
    case warn
    /// Something failed.
    case error
}
