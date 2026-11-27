/// What `keyboard.toml` in dots asks of the keyboard: the hyper key, the key remaps and the shortcuts.
struct KeyboardConfig: Equatable, Sendable {
    /// What reading `keyboard.toml` gave: the config, or nil when an error stops it, and every problem found.
    typealias Reading = (config: Self?, problems: [ConfigProblem])

    /// The keyboard module's id, which names its file in dots.
    static let module = "keyboard"

    /// The key that holds every modifier down, or nil when there's none.
    let hyperKey: Key?
    /// The key remaps, by the name of the key pressed.
    let remaps: [KeyRemap]
    /// The shortcuts, by table and then by key.
    let bindings: [KeyBinding]

    /// Creates a config from the hyper key, the remaps and the shortcuts.
    init(hyperKey: Key? = nil, remaps: [KeyRemap] = [], bindings: [KeyBinding] = []) {
        self.hyperKey = hyperKey
        self.remaps = remaps
        self.bindings = bindings
    }

    /// Reads `text`, the contents of `keyboard.toml`, through `KeyboardCatalog`.
    static func read(_ text: String) -> Reading {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.moduleTOMLName(module))
        } catch {
            return (nil, [error])
        }
        let catalog = KeyboardCatalog.catalog
        // `enabled` is reported by the config, which says it belongs in `malum.toml`.
        reader.unknownKeys(
            reader.document.filter { $0.key != ConfigSchema.switchKey }, at: [], known: catalog.topTables)
        let own = catalog.own(&reader, home: "")
        var hyperKey: Key?
        if case .string(let name)? = own.value(at: [KeyboardCatalog.hyperTable, KeyboardCatalog.hyperKey]) {
            hyperKey = Key.named(name)
        }
        let remaps = Self.remaps(own, hyperKey: hyperKey, reader: &reader)
        let bindings = Self.bindings(own, reader: &reader)
        let problems = reader.problemsByLine
        guard !reader.hasErrors else { return (nil, problems) }
        return (Self(hyperKey: hyperKey, remaps: remaps, bindings: bindings), problems)
    }

    /// The remaps in `[remaps]` of `own`, the tables the catalog read, each written as
    /// `pressed = "types_as"`. The hyper key can't be one.
    private static func remaps(_ own: ConfigTable, hyperKey: Key?, reader: inout TableReader) -> [KeyRemap] {
        let table = reader.table(own, KeyboardCatalog.remapsTable, at: [])
        return table.sorted { $0.key < $1.key }.compactMap { name, value in
            let path = [KeyboardCatalog.remapsTable, name]
            guard let from = Self.key(named: name, at: path, reader: &reader) else { return nil }
            guard case .string(let target) = value, let to = Key.named(target) else {
                reader.expect(path, MessageText.keyName)
                return nil
            }
            guard from != hyperKey else {
                reader.add(.error, at: path, .remapsHyperKey(TableReader.dotted(path), name))
                return nil
            }
            return KeyRemap(from: from, to: to)
        }
    }

    /// The shortcuts in `[shortcuts]` of `own`, the tables the catalog read, each written as
    /// `"modifiers+key" = "action"`. A shortcut written twice, in any order of its modifiers, is an
    /// error.
    private static func bindings(_ own: ConfigTable, reader: inout TableReader) -> [KeyBinding] {
        let table = reader.table(own, KeyboardCatalog.shortcutsTable, at: [])
        var first: [Hotkey: [String]] = [:]
        return table.sorted { $0.key < $1.key }.compactMap { written, value in
            let path = [KeyboardCatalog.shortcutsTable, written]
            guard let hotkey = Hotkey(written) else {
                reader.add(.error, at: path, .notShortcut(TableReader.dotted(path)))
                return nil
            }
            if let earlier = first[hotkey] {
                reader.add(.error, at: path, .setTwice(TableReader.dotted(path), TableReader.dotted(earlier)))
                return nil
            }
            first[hotkey] = path
            guard let action = Self.action(value, at: path, reader: &reader) else { return nil }
            return KeyBinding(hotkey: hotkey, action: action, written: written)
        }
    }

    /// The key called `name`, found at `path`, or nil and an error when no key is.
    private static func key(named name: String, at path: [String], reader: inout TableReader) -> Key? {
        guard let key = Key.named(name) else {
            reader.add(.error, at: path, .notKeyName(TableReader.dotted(path), name))
            return nil
        }
        return key
    }

    /// The action `value`, found at `path`, or nil and an error when it isn't a bundle ID or a
    /// module's action.
    private static func action(_ value: ConfigValue, at path: [String], reader: inout TableReader) -> KeyAction? {
        guard case .string(let text) = value, let action = KeyAction(text) else {
            reader.expect(path, MessageText.keyAction)
            return nil
        }
        if case .app(let bundleID) = action, !AppBundle.isBundleID(bundleID) {
            reader.add(.error, at: path, .notBundleID(TableReader.dotted(path)))
            return nil
        }
        return action
    }
}
