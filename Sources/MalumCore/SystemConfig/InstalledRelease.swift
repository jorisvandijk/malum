import Foundation

/// A release Malum installed, as its record in the state folder keeps it.
public struct InstalledRelease: Codable, Equatable, Sendable {
    /// The repository it came from.
    public let repo: String
    /// The release's tag.
    public let tag: String
    /// Where it was installed: the program, or the `.app`.
    public let path: String

    /// The file in the state folder that records every release Malum installed, by name.
    static let recordName = "releases.json"

    /// Creates the record of the release `tag` of `repo`, installed at `path`.
    public init(repo: String, tag: String, path: String) {
        self.repo = repo
        self.tag = tag
        self.path = path
    }

    /// The releases in the record's `text`, by name. A record that can't be read counts as empty, so
    /// everything gets installed again.
    static func record(from text: String?) -> [String: Self] {
        guard let data = text?.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Self].self, from: data)) ?? [:]
    }

    /// The record of `releases` as text.
    static func text(of releases: [String: Self]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(releases), let text = String(bytes: data, encoding: .utf8) else {
            return "{}\n"
        }
        return text + "\n"
    }
}
