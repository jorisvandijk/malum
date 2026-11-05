// MARK: - CustomStringConvertible

extension SettingKind: CustomStringConvertible {
    /// The kind in the words a config problem uses.
    public var description: String {
        switch self {
        case .boolean:
            "true or false"
        case .integer:
            "a whole number"
        case .number:
            "a number"
        case .string:
            "text in quotes"
        case .strings:
            "a list of text in quotes"
        case .table:
            "a table"
        }
    }
}
