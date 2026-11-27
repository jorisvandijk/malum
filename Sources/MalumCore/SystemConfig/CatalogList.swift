import Foundation

/// The kinds of list a curated setting takes, each item written as macOS or the app keeps it.
enum CatalogList: Equatable, Sendable {
    /// Keyboard layouts, by the words in `layouts`.
    case keyboardLayouts
    /// Apps in the Dock, by their full paths.
    case dockApps
    /// Folders in the Dock, by their full paths.
    case dockFolders
    /// Host names or patterns, such as ssh's, each without spaces.
    case hosts
    /// Apps by their bundle IDs, such as the ones to open at start.
    case apps
    /// Names of files or folders, such as apps in `/Applications` without `.app`.
    case names

    /// A keyboard layout's ID and the name macOS keeps it under, by the word `macos.toml` uses.
    struct Layout: Sendable {
        /// The word `macos.toml` uses, such as `us`.
        let word: String
        /// The layout's ID.
        let id: Int
        /// The name macOS keeps it under, such as `U.S.`.
        let name: String
    }

    // swiftlint:disable no_magic_numbers
    // A lookup table: each row names the ID macOS gives the layout.
    /// The keyboard layouts `input_sources` takes.
    static let layouts = [
        Layout(word: "us", id: 0, name: "U.S."),
        Layout(word: "us_international", id: 15000, name: "USInternational-PC"),
        Layout(word: "abc", id: 252, name: "ABC"),
        Layout(word: "british", id: 2, name: "British"),
        Layout(word: "dutch", id: 26, name: "Dutch"),
        Layout(word: "german", id: 3, name: "German"),
        Layout(word: "french", id: 1, name: "French"),
        Layout(word: "dvorak", id: 16300, name: "Dvorak"),
        Layout(word: "colemak", id: 12825, name: "Colemak"),
    ]
    /// How the Dock names a file's address: as a file URL.
    private static let urlKind = 15
    // swiftlint:enable no_magic_numbers

    /// The keys macOS keeps an input source and a Dock item under.
    private enum Key {
        /// The kind of an input source.
        static let sourceKind = "InputSourceKind"
        /// A keyboard layout's ID.
        static let layoutID = "KeyboardLayout ID"
        /// A keyboard layout's name.
        static let layoutName = "KeyboardLayout Name"
        /// A Dock item's details.
        static let tileData = "tile-data"
        /// A Dock item's kind.
        static let tileType = "tile-type"
        /// The file a Dock item shows.
        static let fileData = "file-data"
        /// A file's address.
        static let url = "_CFURLString"
        /// How a file's address is written.
        static let urlType = "_CFURLStringType"
    }

    /// The values macOS gives the kind of an input source and a Dock item.
    private enum Kind {
        /// An input source that is a keyboard layout.
        static let layout = "Keyboard Layout"
        /// A Dock item that is an app.
        static let appTile = "file-tile"
        /// A Dock item that is a folder.
        static let folderTile = "directory-tile"
    }

    /// The fewest items the list takes: a Mac needs a keyboard layout and a key a host, but the
    /// Dock can keep no apps or folders.
    var minimum: Int {
        self == .keyboardLayouts || self == .hosts ? 1 : 0
    }

    /// `item` as macOS keeps it, or nil when it isn't an item of this list.
    func item(_ item: String) -> ConfigValue? {
        switch self {
        case .keyboardLayouts:
            Self.layouts.first { $0.word == item }.map(Self.inputSource)
        case .dockApps:
            Self.tile(item, kind: Kind.appTile)
        case .dockFolders:
            Self.tile(item, kind: Kind.folderTile)
        case .hosts:
            item.isEmpty || item.contains(where: \.isWhitespace) ? nil : .string(item)
        case .apps:
            AppBundle.isBundleID(item) ? .string(item) : nil
        case .names:
            Paths.isPlainName(item) ? .string(item) : nil
        }
    }

    /// The input source of `layout`.
    private static func inputSource(_ layout: Layout) -> ConfigValue {
        .table([
            Key.sourceKind: .string(Kind.layout),
            Key.layoutID: .integer(layout.id),
            Key.layoutName: .string(layout.name),
        ])
    }

    /// The Dock item of kind `kind` for what's at `path`, or nil when it isn't a full path.
    private static func tile(_ path: String, kind: String) -> ConfigValue? {
        guard path.hasPrefix("/") else { return nil }
        let url = URL(fileURLWithPath: path, isDirectory: true).absoluteString
        let file: ConfigTable = [Key.url: .string(url), Key.urlType: .integer(urlKind)]
        return .table([Key.tileData: .table([Key.fileData: .table(file)]), Key.tileType: .string(kind)])
    }
}
