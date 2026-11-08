import Foundation

/// Every way Malum runs `pmset`, which reads and changes the power settings.
public enum Pmset {
    /// A power source `macos.toml` can set, by the name it gives it.
    public enum Source: String, CaseIterable, Sendable {
        /// Running on the battery.
        case battery
        /// Running on the charger.
        case charger

        /// The flag that makes `pmset` change this source's settings.
        var flag: String { self == .battery ? "-b" : "-c" }

        /// The line that heads this source's settings in the output of `custom`.
        var heading: String { self == .battery ? "Battery Power:" : "AC Power:" }
    }

    /// Where macOS keeps `pmset`.
    public static let path = "/usr/bin/pmset"

    /// Prints the settings of every power source this Mac has.
    public static let custom = Command(path, ["-g", "custom"])

    /// Sets `setting` to `value` on `source`. Only root can run it.
    public static func set(_ setting: String, to value: Int, on source: Source) -> Command {
        Command(path, [source.flag, setting, String(value)])
    }

    /// The settings in the output of `custom`, by source and name. A source this Mac lacks isn't in it.
    static func settings(in output: String) -> [Source: [String: Int]] {
        var settings: [Source: [String: Int]] = [:]
        var source: Source?
        for line in output.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.hasSuffix(":") {
                source = Source.allCases.first { $0.heading == line }
                continue
            }
            let words = line.split(whereSeparator: \.isWhitespace)
            guard let source, let last = words.last, let value = Int(last), words.count > 1 else { continue }
            settings[source, default: [:]][words.dropLast().joined(separator: " ")] = value
        }
        return settings
    }
}
