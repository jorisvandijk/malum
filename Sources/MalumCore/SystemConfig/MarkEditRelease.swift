import Foundation

/// The latest release of one MarkEdit extension, as MarkEdit's registry lists it.
struct MarkEditRelease: Decodable, Equatable, Sendable {
    /// The release's version, such as `1.14.1`.
    let version: String
    /// Where its script downloads from.
    let url: String
    /// The script's SHA-256 checksum.
    let sha256: String

    /// The registry's file: every extension, each with its latest release.
    private struct Index: Decodable {
        /// Every extension and theme.
        let extensions: [Entry]
    }

    /// One extension in the registry.
    private struct Entry: Decodable {
        /// The extension's id, which names its script.
        let id: String
        /// Its latest release.
        let latest: MarkEditRelease
    }

    /// The latest release of each extension in `data`, the registry's file, by id.
    static func index(from data: Data) throws(MarkEditError) -> [String: MarkEditRelease] {
        let index: Index
        do {
            index = try JSONDecoder().decode(Index.self, from: data)
        } catch {
            throw .unreadableRegistry
        }
        return Dictionary(index.extensions.map { ($0.id, $0.latest) }) { first, _ in first }
    }
}
