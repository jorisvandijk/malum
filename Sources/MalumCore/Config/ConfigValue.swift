import TOMLKit

/// A table from `malum.toml`, such as one module's settings.
public typealias ConfigTable = [String: ConfigValue]

/// A value from `malum.toml`, copied out of the parser so it can be compared and passed between actors.
public enum ConfigValue: Equatable, Sendable {
    /// Text.
    case string(String)
    /// A whole number.
    case integer(Int)
    /// A number with a fraction.
    case float(Double)
    /// True or false.
    case boolean(Bool)
    /// A date, a time or both, as written.
    case date(String)
    /// A list of values.
    case array([ConfigValue])
    /// A table of named values.
    case table(ConfigTable)

    /// Copies a value the parser read. Each accessor matches the type it's picked by, so the
    /// fallbacks after `??` are never used.
    init(_ value: any TOMLValueConvertible) {
        switch value.type {
        case .string:
            self = .string(value.string ?? "")
        case .int:
            self = .integer(value.int ?? 0)
        case .double:
            self = .float(value.double ?? 0)
        case .bool:
            self = .boolean(value.bool ?? false)
        case .date, .time, .dateTime:
            self = .date(value.debugDescription)
        case .array:
            self = .array(value.array.map { $0.map(ConfigValue.init) } ?? [])
        case .table:
            self = .table(value.table.map(Self.table) ?? [:])
        }
    }

    /// Copies a whole table the parser read.
    static func table(_ table: TOMLTable) -> ConfigTable {
        var copy: ConfigTable = [:]
        for key in table.keys {
            guard let value = table[key] else { continue }
            copy[key] = ConfigValue(value)
        }
        return copy
    }
}
