import Foundation

/// What Malum installed or took over, kept in the state folder and shaped like `packages.toml`,
/// plus the app config files it wrote, the app preferences it set and the VSCodium extensions it
/// installed. Only what's in here is ever
/// uninstalled or removed.
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
    /// The app config files Malum wrote, by their full path.
    public var files: [String: ManagedFile] = [:]
    /// The app preferences Malum set, by their domain.
    public var preferences: [String: ManagedPreferences] = [:]
    /// The VSCodium extensions, as `apps/vscodium.toml` lists them.
    public var extensions: Set<String> = []

    /// Creates an empty record.
    public init() {}

    /// The record's keys, named like the tables of `packages.toml`.
    private enum CodingKeys: String, CodingKey {
        case homebrew
        case appStore = "app_store"
        case releases = "release"
        case files
        case preferences
        case extensions = "vscodium_extensions"
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
        files = try container.decodeIfPresent([String: ManagedFile].self, forKey: .files) ?? [:]
        preferences = try container.decodeIfPresent([String: ManagedPreferences].self, forKey: .preferences) ?? [:]
        extensions = Set(try container.decodeIfPresent([String].self, forKey: .extensions) ?? [])
    }

    /// Writes the record, sorted, so the file only changes when the record does.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var homebrew = container.nestedContainer(keyedBy: HomebrewKeys.self, forKey: .homebrew)
        try homebrew.encode(formulae.sorted(), forKey: .formulae)
        try homebrew.encode(casks.sorted(), forKey: .casks)
        try container.encode(appStore, forKey: .appStore)
        try container.encode(releases, forKey: .releases)
        try container.encode(files, forKey: .files)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(extensions.sorted(), forKey: .extensions)
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

    /// Reads the record from `state`, or reports that `what` couldn't be done and gives nil.
    static func read(from state: StateFolder, for what: MessageText, report: (Message) -> Void) -> Self? {
        do {
            return try read(from: state)
        } catch {
            report(.failed(what, error))
            return nil
        }
    }

    /// Makes `change` to the record in `state`, reporting when it can't. Says whether it worked.
    static func remember(in state: StateFolder, report: (Message) -> Void, _ change: (inout Self) -> Void) -> Bool {
        do {
            try Self.change(in: state, change)
            return true
        } catch {
            report(.failed(.recordManaged, error))
            return false
        }
    }

    /// Makes `change` to the record in `state`, holding the state folder's lock from the read to
    /// the write. When the record can't be read or written, the file stays as it is.
    static func change(in state: StateFolder, _ change: (inout Self) -> Void) throws {
        var failure: RecordError?
        try state.update(fileName) { text in
            do throws(RecordError) {
                var record = try decode(text, at: state.path(of: fileName))
                change(&record)
                return try record.text()
            } catch {
                failure = error
                return nil
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
            throw .unreadable(path: path)
        }
    }

    /// The record as text.
    private func text() throws(RecordError) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data: Data
        do {
            data = try encoder.encode(self)
        } catch {
            throw .unwritable(reason: error.localizedDescription)
        }
        guard let text = String(bytes: data, encoding: .utf8) else { throw .unwritable(reason: "it isn't UTF-8") }
        return text + "\n"
    }
}
