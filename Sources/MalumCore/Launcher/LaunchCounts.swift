import Foundation

/// How often each app was started from the launcher, kept in the state folder so the apps used
/// most come first.
public struct LaunchCounts: Sendable {
    /// The file in the state folder.
    static let fileName = "launches.json"

    /// Malum's state folder.
    private let state: StateFolder

    /// Creates the counts in `state`.
    public init(state: StateFolder) {
        self.state = state
    }

    /// The count of every app by its key, empty when nothing was started yet.
    public func read() throws(StateError) -> [String: Int] {
        guard let text = try state.read(Self.fileName) else { return [:] }
        return Self.decode(text)
    }

    /// Adds one to the count of the app with `key`.
    public func record(_ key: String) throws(StateError) {
        try state.update(Self.fileName) { text in
            var counts = text.map(Self.decode) ?? [:]
            counts[key, default: 0] += 1
            return Self.encode(counts)
        }
    }

    /// The counts in `text`, empty when it isn't a count file, so a damaged file starts over.
    private static func decode(_ text: String) -> [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: Data(text.utf8))) ?? [:]  // Damaged: start over.
    }

    /// `counts` as the file's text.
    private static func encode(_ counts: [String: Int]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(counts)).flatMap { String(data: $0, encoding: .utf8) }  // Numbers always encode.
    }
}
