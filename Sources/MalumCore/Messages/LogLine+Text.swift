/// How `malum log` shows an entry.
extension LogLine: CustomStringConvertible {
    /// The time, the part of Malum and the text, such as `00:12:01 keyboard [info] remaps set again`.
    public var description: String {
        "\(time) \(category) \(text)"
    }
}
