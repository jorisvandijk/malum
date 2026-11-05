/// Escapes text for the file formats Malum writes, so every format shares one set of rules.
enum Escaping {
    /// What a quoted string escapes besides backslashes and double quotes.
    enum Controls {
        /// Nothing else.
        case none
        /// Line breaks and tabs, as `\n` and `\t`.
        case breaks
        /// Line breaks and tabs, and every other control character as `\uXXXX`.
        case all
    }

    /// How many hex digits a `\u` escape has.
    private static let escapeDigits = 4
    /// The base of a hex number.
    private static let hexRadix = 16
    /// The characters a shell takes as they are, outside quotes.
    private static let shellSafe = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/._-+@:,=")

    /// `text` in double quotes, with backslashes, double quotes and `controls` escaped, as TOML,
    /// JSON and git's config read it.
    static func quoted(_ text: String, controls: Controls) -> String {
        let escaped = text.unicodeScalars.map { scalar in
            switch (scalar, controls) {
            case ("\\", _):
                "\\\\"
            case ("\"", _):
                "\\\""
            case ("\n", .breaks), ("\n", .all):
                "\\n"
            case ("\t", .breaks), ("\t", .all):
                "\\t"
            case (_, .all) where scalar.properties.generalCategory == .control:
                unicodeEscape(scalar)
            default:
                String(scalar)
            }
        }
        return "\"" + escaped.joined() + "\""
    }

    /// `text` made safe to put between XML tags.
    static func xml(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// `text` as it's pasted into a shell: as it is when that's safe, in single quotes otherwise.
    static func shell(_ text: String) -> String {
        guard !text.allSatisfy(shellSafe.contains) else { return text }
        return "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// A control character as a `\uXXXX` escape.
    private static func unicodeEscape(_ scalar: Unicode.Scalar) -> String {
        let hex = String(scalar.value, radix: hexRadix, uppercase: true)
        return "\\u" + String(repeating: "0", count: max(0, escapeDigits - hex.count)) + hex
    }
}
