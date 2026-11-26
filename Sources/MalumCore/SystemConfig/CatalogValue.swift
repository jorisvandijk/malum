import Foundation

/// The kind of value a curated setting takes, and how it becomes the value of each target the
/// setting writes. Every catalog shares these, so `macos.toml` and every app's file read a
/// duration, a colour or a shortcut the same way.
enum CatalogValue: Equatable, Sendable {
    /// True or false, written as it is.
    case flag
    /// True or false, written the other way round, for a target an app names by what's off, such
    /// as `DSDontWriteNetworkStores`.
    case invertedFlag
    /// True or false, written as `on` or `off`, for a target an app keeps as a number.
    case flagAs(on: ConfigValue, off: ConfigValue)
    /// True or false, each with what it writes to each target, for a switch that sets several.
    case combinedFlag(on: [CatalogSetting.Write], off: [CatalogSetting.Write])
    /// One of a few words, each with what it writes to each target.
    case choice([CatalogChoice])
    /// Milliseconds in `range`, written as a count of steps of `step` milliseconds, rounded.
    case milliseconds(step: Int, range: ClosedRange<Int>)
    /// Whole seconds in `range`, written as they are.
    case seconds(ClosedRange<Int>)
    /// Whole minutes in `range`, written as they are.
    case minutes(ClosedRange<Int>)
    /// A whole percentage, written as a fraction from 0 to 1.
    case percent
    /// A folder's full path.
    case folder
    /// A path, `$HOME/` for one in the home folder, written with the home folder filled in.
    case path
    /// A colour, `#rrggbb` in lowercase, written as it is.
    case color
    /// A table of a text colour `fg`, an optional background `bg` and an optional `style`, written
    /// as text: the style, a space, then the colours joined by `join`, such as `bold #f8f8f2,#282a36`.
    case colorPair(join: String)
    /// A shortcut in the shared syntax, such as `ctrl+option+k`, written as `style` says.
    case shortcut(ShortcutStyle)
    /// A list of items, each written as the target keeps it.
    case list(CatalogList)

    /// The percentages a `.percent` setting takes.
    static let percentRange = 0...100
    /// What a percentage is divided by to make a fraction.
    private static let percentScale = 100.0
    /// How many values a switch takes: on and off.
    private static let switchValues = 2
    /// What a path in the home folder starts with.
    static let homePrefix = "$HOME/"
    /// The styles a colour pair takes.
    static let colorStyles = ["bold", "italic", "underline"]
    /// The keys of a colour pair: the text colour, the background and the style.
    enum PairKey {
        /// The text colour.
        static let fg = "fg"
        /// The background colour.
        static let bg = "bg"
        /// The style.
        static let style = "style"
        /// Every key, in the order a pair is written.
        static let all = [fg, bg, style]
    }

    /// What `given` writes to each of `targets` targets, or nil when it isn't a value of this kind.
    /// A path in the home folder is filled in with `home`.
    func writes(for given: ConfigValue, targets: Int, home: String) -> [CatalogSetting.Write]? {
        switch (self, given) {
        case (.choice(let choices), .string(let word)):
            return choices.first { $0.word == word }?.writes
        case (.choice, _):
            return nil
        case (.combinedFlag(let on, let off), .boolean(let isOn)):
            return isOn ? on : off
        case (.combinedFlag, _):
            return nil
        default:
            return single(given, home: home).map { Array(repeating: .set($0), count: targets) }
        }
    }

    /// The one value `given` writes to every target, for the kinds that write one, or nil when it
    /// isn't a value of this kind.
    private func single(_ given: ConfigValue, home: String) -> ConfigValue? {
        switch (self, given) {
        case (.flag, .boolean):
            given
        case (.invertedFlag, .boolean(let isOn)):
            .boolean(!isOn)
        case (.flagAs(let on, let off), .boolean(let isOn)):
            isOn ? on : off
        case (.milliseconds, .integer), (.seconds, .integer), (.minutes, .integer), (.percent, .integer):
            number(given)
        case (.list(let list), _):
            TableReader.texts(given).flatMap { $0.count >= list.minimum ? $0.map(list.item).allPresent() : nil }
                .map(ConfigValue.array)
        default:
            text(given, home: home)
        }
    }

    /// The value the whole number `given` writes, for the kinds that take one, or nil when it's out
    /// of range or not a number of this kind.
    private func number(_ given: ConfigValue) -> ConfigValue? {
        switch (self, given) {
        case (.milliseconds(let step, let range), .integer(let milliseconds)) where range.contains(milliseconds):
            .integer(Int((Double(milliseconds) / Double(step)).rounded()))
        case (.seconds(let range), .integer(let number)) where range.contains(number),
            (.minutes(let range), .integer(let number)) where range.contains(number):
            given
        case (.percent, .integer(let percent)) where Self.percentRange.contains(percent):
            .float(Double(percent) / Self.percentScale)
        default:
            nil
        }
    }

    /// The value the text or table `given` writes, for the kinds that take one, or nil when it isn't
    /// a value of this kind.
    private func text(_ given: ConfigValue, home: String) -> ConfigValue? {
        switch (self, given) {
        case (.folder, .string(let path)) where path.hasPrefix("/"):
            given
        case (.path, .string(let path)):
            Self.path(path, home: home).map { ConfigValue.string($0) }
        case (.color, .string(let color)) where Self.isColor(color):
            given
        case (.colorPair(let join), .table(let pair)):
            Self.pair(pair, join: join).map { ConfigValue.string($0) }
        case (.shortcut(let style), .string(let text)):
            Hotkey(text).map(style.value)
        default:
            nil
        }
    }

    /// `path` with the home folder `home` filled in, or nil when it isn't a full path or `$HOME/`
    /// and one, or names the home folder by its own path.
    private static func path(_ path: String, home: String) -> String? {
        if path.hasPrefix(homePrefix) {
            let rest = path.dropFirst(homePrefix.count)
            return rest.isEmpty ? nil : "\(home)/\(rest)"
        }
        guard path.hasPrefix("/"), path != home, !path.hasPrefix(home + "/") else { return nil }
        return path
    }

    /// Whether `text` is a colour: `#` and six lowercase hexadecimal digits.
    static func isColor(_ text: String) -> Bool {
        let digits = text.dropFirst()
        return text.first == "#" && digits.count == colorDigits
            && digits.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    /// How many digits a colour has.
    private static let colorDigits = 6

    /// The colour pair `pair` as text, its colours joined by `join`, or nil when it isn't one.
    private static func pair(_ pair: ConfigTable, join: String) -> String? {
        guard Set(pair.keys).isSubset(of: PairKey.all), case .string(let fg)? = pair[PairKey.fg], isColor(fg)
        else { return nil }
        var colors = fg
        if let bg = pair[PairKey.bg] {
            guard case .string(let bg) = bg, isColor(bg) else { return nil }
            colors += join + bg
        }
        guard let style = pair[PairKey.style] else { return colors }
        guard case .string(let style) = style, colorStyles.contains(style) else { return nil }
        return "\(style) \(colors)"
    }

    /// How many values a setting of this kind can take, as far as it can tell: two for a switch,
    /// the words of a choice, the numbers in a range, or nil for paths, colours, shortcuts and
    /// lists, which take many.
    var choices: Int? {
        switch self {
        case .flag, .invertedFlag, .flagAs, .combinedFlag:
            Self.switchValues
        case .choice(let choices):
            choices.count
        case .milliseconds(let step, let range):
            (range.upperBound - range.lowerBound) / step + 1
        case .seconds(let range), .minutes(let range):
            range.upperBound - range.lowerBound + 1
        case .percent:
            Self.percentRange.count
        case .folder, .path, .color, .colorPair, .shortcut, .list:
            nil
        }
    }
}

/// One word a choice setting takes, and what it writes to each of the setting's targets.
struct CatalogChoice: Equatable, Sendable {
    /// The word, such as `dark`.
    let word: String
    /// What it writes, one per target the setting writes.
    let writes: [CatalogSetting.Write]

    /// Creates the word `word`, which writes `writes`.
    init(_ word: String, _ writes: [CatalogSetting.Write]) {
        self.word = word
        self.writes = writes
    }

    /// The word `word`, which sets the setting's one target to `value`.
    static func word(_ word: String, _ value: ConfigValue) -> Self {
        Self(word, [.set(value)])
    }
}
