/// What `keyboard.toml` in dots asks of the keyboard: the hyper key, the key remaps and the shortcuts.
struct KeyboardConfig: Equatable, Sendable {
    /// What reading `keyboard.toml` gave: the config, or nil when an error stops it, and every problem found.
    typealias Reading = (config: Self?, problems: [ConfigProblem])

    /// The keyboard module's id, which names its file in dots.
    static let module = "keyboard"
    /// The key that names the hyper key.
    private static let hyperKeyKey = "hyper_key"
    /// The table of key remaps.
    private static let remapTable = "remap"

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

    /// Reads `text`, the contents of `keyboard.toml`.
    static func read(_ text: String) -> Reading {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.moduleTOMLName(module))
        } catch {
            return (nil, [error])
        }
        let document = reader.document
        let hyperKey = Self.hyperKey(document[hyperKeyKey], reader: &reader)
        let remaps = Self.remaps(reader.table(document, remapTable, at: []), hyperKey: hyperKey, reader: &reader)
        var bindings: [KeyBinding] = []
        let tables = document.filter { ![hyperKeyKey, remapTable].contains($0.key) }
        for (name, value) in tables.sorted(by: { $0.key < $1.key }) {
            bindings += Self.bindings(inTable: name, value, reader: &reader)
        }
        let problems = reader.problemsByLine
        guard !reader.hasErrors else { return (nil, problems) }
        return (Self(hyperKey: hyperKey, remaps: remaps, bindings: bindings), problems)
    }

    /// The hyper key named by `value`, or nil when it's left out or isn't a key that can be one.
    private static func hyperKey(_ value: ConfigValue?, reader: inout TableReader) -> Key? {
        guard let value else { return nil }
        guard case .string(let name) = value, let key = Key.named(name), key.canBeHyper else {
            reader.expect([hyperKeyKey], MessageText.hyperKeyName)
            return nil
        }
        return key
    }

    /// The remaps in `table`, each written as `pressed = "types_as"`. The hyper key can't be one.
    private static func remaps(_ table: ConfigTable, hyperKey: Key?, reader: inout TableReader) -> [KeyRemap] {
        table.sorted { $0.key < $1.key }.compactMap { name, value in
            let path = [remapTable, name]
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

    /// The shortcuts in the table `name` at the top of the file, with `value` its contents, or none
    /// when it isn't a table of modifiers written in their order.
    private static func bindings(inTable name: String, _ value: ConfigValue, reader: inout TableReader) -> [KeyBinding]
    {
        guard let modifiers = Modifier.modifiers(inTable: name) else {
            reader.unknownKeys([name: value], at: [], known: [])
            return []
        }
        let spelling = Modifier.table(of: modifiers)
        guard spelling == name else {
            reader.add(.error, at: [name], .modifierOrder(name, spelling))
            return []
        }
        guard let table = reader.table(value, at: [name]) else { return [] }
        return table.sorted { $0.key < $1.key }.compactMap { keyName, value in
            let path = [name, keyName]
            guard let key = Self.key(named: keyName, at: path, reader: &reader) else { return nil }
            guard let action = Self.action(value, at: path, reader: &reader) else { return nil }
            return KeyBinding(modifiers: modifiers, key: key, action: action)
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
