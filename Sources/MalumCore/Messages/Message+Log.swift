/// The messages of `malum log`.
extension Message {
    /// `log` couldn't read the unified log.
    static func logUnreadable(reason: String) -> Message {
        couldnt("read the log", "\(reason)")
    }
}
