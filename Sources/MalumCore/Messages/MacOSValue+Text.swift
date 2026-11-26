// MARK: - CustomStringConvertible

extension MacOSValue: CustomStringConvertible {
    /// The values a setting of this kind takes, in the words a config problem and the docs use.
    var description: String {
        switch self {
        case .flag, .invertedFlag, .flagAs, .combinedFlag:
            SettingKind.boolean.description
        case .choice(let choices):
            Self.oneOf(choices.map(\.word))
        case .milliseconds(let step, let range):
            "milliseconds from \(range.lowerBound) to \(range.upperBound), in steps of \(step)"
        case .percent:
            "a whole number from \(Self.percentRange.lowerBound) to \(Self.percentRange.upperBound)"
        case .folder:
            "a folder's full path, starting with /"
        case .list(let list):
            list.description
        }
    }

    /// `words` in quotes, as a choice of one of them: `"a", "b" or "c"`.
    static func oneOf(_ words: [String]) -> String {
        let quoted = words.map { "\"\($0)\"" }
        guard let last = quoted.last, quoted.count > 1 else { return quoted.first ?? "" }
        return quoted.dropLast().joined(separator: ", ") + " or " + last
    }
}

// MARK: - CustomStringConvertible

extension MacOSList: CustomStringConvertible {
    /// What the list holds, in the words a config problem and the docs use.
    var description: String {
        switch self {
        case .keyboardLayouts:
            "a list of at least one keyboard layout, each " + MacOSValue.oneOf(Self.layouts.map(\.word))
        case .dockApps:
            "a list of apps' full paths, such as \"/Applications/Safari.app\""
        case .dockFolders:
            "a list of folders' full paths, such as \"/Users/you/Downloads\""
        }
    }
}

// MARK: - CustomStringConvertible

extension PowerSetting.Kind: CustomStringConvertible {
    /// The values a power setting of this kind takes, in the words a config problem and the docs use.
    var description: String {
        switch self {
        case .flag:
            SettingKind.boolean.description
        case .minutes:
            "a whole number of minutes, 0 for never"
        }
    }
}
