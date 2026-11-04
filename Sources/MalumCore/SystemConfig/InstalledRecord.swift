import Foundation

/// What Malum installed or took over, kept in the state folder and shaped like `packages.toml`.
/// Only what's in here is ever uninstalled.
public struct InstalledRecord: Codable, Equatable, Sendable {
    /// The record's file in the state folder.
    static let fileName = "installed.json"

    /// The Homebrew formulae, by the name `packages.toml` gives them.
    public var formulae: Set<String> = []
    /// The Homebrew casks, by the name `packages.toml` gives them.
    public var casks: Set<String> = []
    /// The App Store apps, by their name in `packages.toml`, with their App Store ID.
    public var appStore: [String: Int] = [:]
    /// The GitHub releases, by their name in `packages.toml`.
    public var releases: [String: InstalledRelease] = [:]

    /// Creates an empty record.
    public init() {}

    /// The record's keys, named like the tables of `packages.toml`.
    private enum CodingKeys: String, CodingKey {
        case homebrew
        case appStore = "app_store"
        case releases = "release"
    }

    /// The Homebrew packages' keys, named like the values in `packages.toml`.
    private enum HomebrewKeys: String, CodingKey {
        case formulae = "formula"
        case casks = "cask"
    }

    /// Reads the record; any part it lacks is empty.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.homebrew) {
            let homebrew = try container.nestedContainer(keyedBy: HomebrewKeys.self, forKey: .homebrew)
            formulae = Set(try homebrew.decodeIfPresent([String].self, forKey: .formulae) ?? [])
            casks = Set(try homebrew.decodeIfPresent([String].self, forKey: .casks) ?? [])
        }
        appStore = try container.decodeIfPresent([String: Int].self, forKey: .appStore) ?? [:]
        releases = try container.decodeIfPresent([String: InstalledRelease].self, forKey: .releases) ?? [:]
    }

    /// Writes the record, sorted, so the file only changes when the record does.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var homebrew = container.nestedContainer(keyedBy: HomebrewKeys.self, forKey: .homebrew)
        try homebrew.encode(formulae.sorted(), forKey: .formulae)
        try homebrew.encode(casks.sorted(), forKey: .casks)
        try container.encode(appStore, forKey: .appStore)
        try container.encode(releases, forKey: .releases)
    }

    /// The Homebrew packages of `kind`.
    public subscript(kind: PackageKind) -> Set<String> {
        get { kind == .formula ? formulae : casks }
        set {
            switch kind {
            case .formula:
                formulae = newValue
            case .cask:
                casks = newValue
            }
        }
    }

    /// Reads the record from `state`. There's none before Malum installs anything.
    static func read(from state: StateFolder) throws -> Self {
        try decode(try state.read(fileName), at: state.path(of: fileName))
    }

    /// Makes `change` to the record in `state`, holding the state folder's lock from the read to
    /// the write.
    static func change(in state: StateFolder, _ change: (inout Self) -> Void) throws {
        var failure: (any Error)?
        try state.update(fileName) { text in
            do {
                var record = try decode(text, at: state.path(of: fileName))
                change(&record)
                return record.text
            } catch {
                failure = error
                return text ?? ""
            }
        }
        if let failure { throw failure }
    }

    /// The record in `text`, the file at `path`, or an empty one when there's no text.
    private static func decode(_ text: String?, at path: String) throws(RecordError) -> Self {
        guard let text else { return Self() }
        do {
            return try JSONDecoder().decode(Self.self, from: Data(text.utf8))
        } catch {
            throw RecordError("couldn't read \(private: path), the record of what Malum installed")
        }
    }

    /// The record as text.
    private var text: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self), let text = String(bytes: data, encoding: .utf8) else {
            return "{}\n"
        }
        return text + "\n"
    }
}
