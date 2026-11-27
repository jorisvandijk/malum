// MARK: - CustomStringConvertible

extension CatalogValue: CustomStringConvertible {
    /// The values a setting of this kind takes, in the words a config problem and the docs use.
    var description: String {
        switch self {
        case .flag, .invertedFlag, .flagAs, .combinedFlag:
            SettingKind.boolean.description
        case .choice(let choices):
            Self.oneOf(choices.map(\.word))
        case .milliseconds(let step, let range):
            "milliseconds from \(range.lowerBound) to \(range.upperBound), in steps of \(step)"
        case .seconds(let range):
            Self.whole("seconds", range)
        case .minutes(let range):
            Self.whole("minutes", range)
        case .count(let range):
            Self.whole(nil, range)
        case .number(let unit, let range, _):
            "a number of \(unit.words) from \(Self.plain(range.lowerBound)) to \(Self.plain(range.upperBound))"
        case .percent:
            "a whole number from \(Self.percentRange.lowerBound) to \(Self.percentRange.upperBound)"
        case .folder:
            "a folder's full path, starting with /"
        case .path:
            "a path, starting with \(Self.homePrefix) in your home folder or / outside it"
        case .app:
            "an app's bundle ID, such as \"net.librewolf.librewolf\""
        case .text:
            "text that isn't empty"
        case .color:
            "a colour, # and six lowercase hexadecimal digits, such as \"#f8f8f2\""
        case .colorPair(_, let unset):
            "a table with a colour fg\(unset == nil ? "" : " (or none, for the default)"), an optional colour bg "
                + "and an optional style " + Self.oneOf(Self.colorStyles)
                + ", such as { fg = \"#f8f8f2\", bg = \"#282a36\" }"
        case .colorPairKeys:
            "a table with a colour fg and a colour bg, such as { fg = \"#f8f8f2\", bg = \"#282a36\" }"
        case .shortcut:
            Self.shortcut
        case .shortcutKeys:
            "\(Self.shortcut), or a list of them"
        case .list(let list):
            list.description
        case .parts(let parts, _, let none):
            (none == nil ? "a list of at least one of " : "a list of any of ") + Self.oneOf(parts.map(\.word))
        case .partList(let parts):
            "a list of at least one of " + Self.oneOf(parts.map(\.word)) + ", each as often as you like"
        }
    }

    /// A shortcut in the shared syntax, in the words a config problem and the docs use.
    private static let shortcut =
        "a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as \"ctrl+option+k\""

    /// `number` as a person writes it: with no decimals when it's whole.
    private static func plain(_ number: Double) -> String {
        number.rounded() == number && abs(number) < Double(Int.max) ? String(Int(number)) : String(number)
    }

    /// A whole number of `unit`, or a plain one without it, in `range`, with no upper end when it
    /// reaches `Int.max`.
    private static func whole(_ unit: String?, _ range: ClosedRange<Int>) -> String {
        let number = unit.map { "a whole number of \($0)" } ?? "a whole number"
        guard range.upperBound < Int.max else { return "\(number), \(range.lowerBound) or more" }
        return "\(number) from \(range.lowerBound) to \(range.upperBound)"
    }

    /// `words` in quotes, as a choice of one of them: `"a", "b" or "c"`.
    static func oneOf(_ words: [String]) -> String {
        let quoted = words.map { "\"\($0)\"" }
        guard let last = quoted.last, quoted.count > 1 else { return quoted.first ?? "" }
        return quoted.dropLast().joined(separator: ", ") + " or " + last
    }
}

// MARK: - CustomStringConvertible

extension CatalogList: CustomStringConvertible {
    /// What the list holds, in the words a config problem and the docs use.
    var description: String {
        switch self {
        case .keyboardLayouts:
            "a list of at least one keyboard layout, each " + CatalogValue.oneOf(Self.layouts.map(\.word))
        case .dockApps:
            "a list of apps' full paths, such as \"/Applications/Safari.app\""
        case .dockFolders:
            "a list of folders' full paths, such as \"/Users/you/Downloads\""
        case .hosts:
            "a list of at least one host name or pattern, such as \"github.com\" or \"*.example.com\""
        }
    }
}

extension NumberUnit {
    /// The unit in the words a config problem and the docs use.
    var words: String {
        switch self {
        case .pt:
            "points"
        }
    }
}
