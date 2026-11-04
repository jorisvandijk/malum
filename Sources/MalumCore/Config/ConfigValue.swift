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

    /// The value written as TOML, as the docs show it.
    public var toml: String {
        switch self {
        case .string(let text):
            Self.quoted(text)
        case .integer(let number):
            String(number)
        case .float(let number):
            // Swift writes fractions, exponents, inf and nan the way TOML reads them.
            String(number)
        case .boolean(let flag):
            String(flag)
        case .date(let text):
            text
        case .array(let items):
            "[" + items.map(\.toml).joined(separator: ", ") + "]"
        case .table(let table):
            table.isEmpty ? "{}" : "{ " + table.sorted { $0.key < $1.key }.map(Self.pair).joined(separator: ", ") + " }"
        }
    }

    /// One entry of an inline table, as `key = value`.
    private static func pair(_ entry: (key: String, value: ConfigValue)) -> String {
        "\(key(entry.key)) = \(entry.value.toml)"
    }

    /// `name` as a TOML key: bare when TOML allows it, in quotes otherwise.
    static func key(_ name: String) -> String {
        let bare = !name.isEmpty && name.unicodeScalars.allSatisfy { bareKeyCharacters.contains($0) }
        return bare ? name : quoted(name)
    }

    /// The characters a bare TOML key may hold.
    private static let bareKeyCharacters = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-".unicodeScalars)

    /// How many hex digits a `\u` escape has.
    private static let escapeDigits = 4
    /// The base of a hex number.
    private static let hexRadix = 16

    /// `text` as a TOML string in double quotes, with the characters TOML needs escaped.
    private static func quoted(_ text: String) -> String {
        let escaped = text.unicodeScalars.map { scalar in
            switch scalar {
            case "\\":
                "\\\\"
            case "\"":
                "\\\""
            case "\n":
                "\\n"
            case "\t":
                "\\t"
            case _ where scalar.properties.generalCategory == .control:
                unicodeEscape(scalar)
            default:
                String(scalar)
            }
        }
        return "\"" + escaped.joined() + "\""
    }

    /// A control character as a `\uXXXX` escape.
    private static func unicodeEscape(_ scalar: Unicode.Scalar) -> String {
        let hex = String(scalar.value, radix: hexRadix, uppercase: true)
        return "\\u" + String(repeating: "0", count: max(0, escapeDigits - hex.count)) + hex
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
