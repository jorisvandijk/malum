/// The kind of value a setting takes.
public enum SettingKind: Sendable {
    /// True or false.
    case boolean
    /// A whole number.
    case integer
    /// Any number, with or without a fraction.
    case number
    /// Text.
    case string
    /// A list of text.
    case strings
    /// A table, which the module checks itself.
    case table

    /// Whether `value` is of this kind.
    func accepts(_ value: ConfigValue) -> Bool {
        switch (self, value) {
        case (.boolean, .boolean), (.integer, .integer), (.number, .integer), (.number, .float),
            (.string, .string), (.table, .table):
            true
        case (.strings, .array(let items)):
            items.allSatisfy { if case .string = $0 { true } else { false } }
        default:
            false
        }
    }
}

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
