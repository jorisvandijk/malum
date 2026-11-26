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
    /// A number of `unit`, whole or not, in `range`: written as a decimal number when `decimal`,
    /// otherwise as it is.
    case number(NumberUnit, ClosedRange<Double>, decimal: Bool)
    /// A whole percentage, written as a fraction from 0 to 1.
    case percent
    /// A folder's full path.
    case folder
    /// A path, `$HOME/` for one in the home folder, written with the home folder filled in.
    case path
    /// Text that isn't empty, such as a font's or a theme's name, written as `form` says.
    case text(TextForm)
    /// A colour, `#rrggbb` in lowercase, written as it is.
    case color
    /// A table of a text colour `fg`, an optional background `bg` and an optional `style`, written
    /// as text: the style, a space, then the colours joined by `join`, such as `bold #f8f8f2,#282a36`.
    /// With `unset`, `fg` is optional too, and a missing one is written as `unset`, such as micro's
    /// `default` for the terminal's own text colour.
    case colorPair(join: String, unset: String? = nil)
    /// A shortcut in the shared syntax, such as `ctrl+option+k`, written as `style` says.
    case shortcut(ShortcutStyle)
    /// One shortcut in the shared syntax or a list of them, written as `style` says, for a target
    /// that takes each one as a key, such as micro's bindings.
    case shortcutKeys(ShortcutStyle)
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
        case (.number(_, let range, let decimal), _):
            Self.measure(given, in: range, decimal: decimal)
        case (.shortcutKeys(let style), .string(let text)):
            Shortcut(text).flatMap(style.value).map { ConfigValue.array([$0]) }
        case (.shortcutKeys(let style), _):
            TableReader.texts(given).flatMap { texts in
                texts.isEmpty ? nil : texts.map { Shortcut($0).flatMap(style.value) }.allPresent()
            }.map(ConfigValue.array)
        case (.list(let list), _):
            TableReader.texts(given).flatMap { $0.count >= list.minimum ? $0.map(list.item).allPresent() : nil }
                .map(ConfigValue.array)
        default:
            textual(given, home: home)
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
    private func textual(_ given: ConfigValue, home: String) -> ConfigValue? {
        switch (self, given) {
        case (.folder, .string(let path)) where path.hasPrefix("/"):
            given
        case (.path, .string(let path)):
            Self.path(path, home: home).map { ConfigValue.string($0) }
        case (.text(let form), .string(let text)) where !text.isEmpty:
            form.value(text)
        case (.color, .string(let color)) where Self.isColor(color):
            given
        case (.colorPair(let join, let unset), .table(let pair)):
            Self.pair(pair, join: join, unset: unset).map { ConfigValue.string($0) }
        case (.shortcut(let style), .string(let text)):
            Shortcut(text).flatMap(style.value)
        default:
            nil
        }
    }

    /// `path` with the home folder `home` filled in, or nil when it isn't a full path or `$HOME/`
    /// and one, climbs out of the home folder with `..`, or names the home folder by its own path.
    private static func path(_ path: String, home: String) -> String? {
        if path.hasPrefix(homePrefix) {
            let rest = path.dropFirst(homePrefix.count)
            let parts = rest.split(separator: "/", omittingEmptySubsequences: false)
            return rest.isEmpty || parts.contains("..") ? nil : "\(home)/\(rest)"
        }
        guard path.hasPrefix("/"), path != home, !path.hasPrefix(home + "/") else { return nil }
        return path
    }

    /// Whether `text` is a colour: `#` and six lowercase hexadecimal digits.
    static func isColor(_ text: String) -> Bool {
        ScreenshotColor(hex: text)?.hex == text
    }

    /// The number `given` of a unit, when it's in `range`: a decimal number when `decimal`,
    /// otherwise as it is. Nil when it isn't a number in `range`.
    private static func measure(_ given: ConfigValue, in range: ClosedRange<Double>, decimal: Bool) -> ConfigValue? {
        let number: Double
        switch given {
        case .integer(let whole):
            number = Double(whole)
        case .float(let fraction):
            number = fraction
        default:
            return nil
        }
        guard range.contains(number) else { return nil }
        return decimal ? .float(number) : given
    }

    /// The colour pair `pair` as text, its colours joined by `join`, or nil when it isn't one. A
    /// missing text colour is written as `unset`, and is wrong when that's nil.
    private static func pair(_ pair: ConfigTable, join: String, unset: String?) -> String? {
        guard Set(pair.keys).isSubset(of: PairKey.all) else { return nil }
        let colors: String
        switch (pair[PairKey.fg], unset) {
        case (.string(let fg)?, _) where isColor(fg):
            colors = fg
        case (nil, let unset?) where pair[PairKey.bg] != nil:
            colors = unset
        default:
            return nil
        }
        var written = colors
        if let bg = pair[PairKey.bg] {
            guard case .string(let bg) = bg, isColor(bg) else { return nil }
            written += join + bg
        }
        guard let style = pair[PairKey.style] else { return written }
        guard case .string(let style) = style, colorStyles.contains(style) else { return nil }
        return "\(style) \(written)"
    }

    /// How many values a setting of this kind can take, as far as it can tell: two for a switch,
    /// the words of a choice, the numbers in a range, or nil for paths, colours, shortcuts and
    /// lists, which take many, and for numbers with a unit, which needn't be whole.
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
        case .number, .folder, .path, .text, .color, .colorPair, .shortcut, .shortcutKeys, .list:
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

/// The unit of a number a curated setting takes, which the setting's name ends in.
enum NumberUnit: String, Sendable {
    /// Points, as a font's size.
    case pt
    /// Pixels on the screen.
    case px
    /// Lines of text.
    case lines

    /// The end of the name of a setting that takes it, such as `_pt` in `size_pt`.
    var suffix: String {
        "_" + rawValue
    }
}

/// How a text setting's value is written.
enum TextForm: Equatable, Sendable {
    /// As it is.
    case plain
    /// Inside tables, one per key in `keys`, outermost first, such as MarkEdit's
    /// `{ customFont = { name = "..." } }`.
    case nested([String])
    /// As a CSS font list: the name in single quotes, then `fallback` when it's set, such as
    /// `'Menlo', monospace`.
    case fontList(fallback: String?)

    /// `text` written in this form.
    func value(_ text: String) -> ConfigValue {
        switch self {
        case .plain:
            .string(text)
        case .nested(let keys):
            keys.reversed().reduce(ConfigValue.string(text)) { inner, key in .table([key: inner]) }
        case .fontList(let fallback):
            .string((["'\(text)'"] + (fallback.map { [$0] } ?? [])).joined(separator: ", "))
        }
    }
}
