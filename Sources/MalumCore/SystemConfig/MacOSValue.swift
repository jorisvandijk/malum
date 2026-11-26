import Foundation

/// The kind of value a curated macOS setting takes, and how it becomes the value of each
/// preference the setting writes.
enum MacOSValue: Sendable {
    /// True or false, written as it is.
    case flag
    /// True or false, written the other way round, for a preference macOS names by what's off,
    /// such as `DSDontWriteNetworkStores`.
    case invertedFlag
    /// True or false, written as `on` or `off`, for a preference macOS keeps as a number.
    case flagAs(on: ConfigValue, off: ConfigValue)
    /// True or false, each with what it writes to each preference, for a switch that sets several.
    case combinedFlag(on: [MacOSSetting.Write], off: [MacOSSetting.Write])
    /// One of a few words, each with what it writes to each preference.
    case choice([MacOSChoice])
    /// Milliseconds in `range`, written as a count of steps of `step` milliseconds, rounded.
    case milliseconds(step: Int, range: ClosedRange<Int>)
    /// A whole percentage, written as a fraction from 0 to 1.
    case percent
    /// A folder's full path.
    case folder
    /// A list of items, each written as macOS keeps it.
    case list(MacOSList)

    /// The percentages a `.percent` setting takes.
    static let percentRange = 0...100
    /// What a percentage is divided by to make a fraction.
    private static let percentScale = 100.0

    /// What `given` writes to each of `targets` preferences, or nil when it isn't a value of this kind.
    func writes(for given: ConfigValue, targets: Int) -> [MacOSSetting.Write]? {
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
            return single(given).map { Array(repeating: .set($0), count: targets) }
        }
    }

    /// The one value `given` writes to every preference, for the kinds that write one, or nil when
    /// it isn't a value of this kind.
    private func single(_ given: ConfigValue) -> ConfigValue? {
        switch (self, given) {
        case (.flag, .boolean):
            given
        case (.invertedFlag, .boolean(let isOn)):
            .boolean(!isOn)
        case (.flagAs(let on, let off), .boolean(let isOn)):
            isOn ? on : off
        case (.milliseconds(let step, let range), .integer(let milliseconds)) where range.contains(milliseconds):
            .integer(Int((Double(milliseconds) / Double(step)).rounded()))
        case (.percent, .integer(let percent)) where Self.percentRange.contains(percent):
            .float(Double(percent) / Self.percentScale)
        case (.folder, .string(let path)) where path.hasPrefix("/"):
            given
        case (.list(let list), _):
            TableReader.texts(given).flatMap { $0.count >= list.minimum ? $0.map(list.item).allPresent() : nil }
                .map(ConfigValue.array)
        default:
            nil
        }
    }

    /// How many values a setting of this kind can take, as far as it can tell: two for a switch,
    /// the words of a choice, the numbers in a range, or nil for paths and lists, which take many.
    var choices: Int? {
        switch self {
        case .flag, .invertedFlag, .flagAs, .combinedFlag:
            2
        case .choice(let choices):
            choices.count
        case .milliseconds(let step, let range):
            stride(from: range.lowerBound, through: range.upperBound, by: step).count
        case .percent:
            Self.percentRange.count
        case .folder, .list:
            nil
        }
    }
}

/// One word a choice setting takes, and what it writes to each of the setting's preferences.
struct MacOSChoice: Sendable {
    /// The word, such as `dark`.
    let word: String
    /// What it writes, one per preference the setting writes.
    let writes: [MacOSSetting.Write]

    /// Creates the word `word`, which writes `writes`.
    init(_ word: String, _ writes: [MacOSSetting.Write]) {
        self.word = word
        self.writes = writes
    }

    /// The word `word`, which sets the setting's one preference to `value`.
    static func word(_ word: String, _ value: ConfigValue) -> Self {
        Self(word, [.set(value)])
    }
}
