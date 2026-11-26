/// How an app keeps a shortcut, so the shared syntax in dots, such as `ctrl+option+k`, becomes
/// what each app reads.
enum ShortcutStyle: Equatable, Sendable {
    /// Text: fn by `fn` when it's held, the modifiers by `names`, in `Modifier`'s order, then the
    /// key's name, joined by `joiner`, such as kitty's `ctrl+alt+k`. A key in `keys` is written by
    /// its name there, and a whole shortcut in `whole`, by its shared syntax, as its text there,
    /// such as micro's `CtrlUnderscore` for `ctrl+slash`. An app with no `fn` name takes no
    /// shortcut that holds fn, and one with no name for a modifier takes no shortcut that holds it.
    case text(
        names: [Modifier: String], fn: String?, joiner: String, keys: [String: String] = [:],
        whole: [String: String] = [:])
    /// The Carbon key code and modifiers as JSON text, as apps built with KeyboardShortcuts keep
    /// them: `{"carbonKeyCode":40,"carbonModifiers":6144}`. Carbon has no fn.
    case carbonJSON
    /// A table of the Carbon key code under `keyCode` and the modifiers under `modifiers`.
    case carbonTable(keyCode: String, modifiers: String)

    /// The shared syntax itself, for an app that reads it as it is.
    static let shared = text(
        names: Dictionary(uniqueKeysWithValues: Modifier.allCases.map { ($0, $0.rawValue) }), fn: Shortcut.fn,
        joiner: Hotkey.joiner)

    // swiftlint:disable no_magic_numbers
    // Platform constants: Carbon's modifier masks from `Events.h`.
    /// The Carbon mask of each modifier.
    private static let carbonMasks: [Modifier: Int] = [.cmd: 256, .shift: 512, .option: 2048, .ctrl: 4096]
    // swiftlint:enable no_magic_numbers

    /// The keys KeyboardShortcuts' JSON keeps a shortcut under.
    private enum JSONKey {
        /// The key code.
        static let keyCode = "carbonKeyCode"
        /// The modifiers.
        static let modifiers = "carbonModifiers"
    }

    /// `shortcut` as text in this style, or nil when it isn't a text style or can't take it.
    private func text(_ shortcut: Shortcut) -> String? {
        guard case .string(let text)? = value(shortcut) else { return nil }
        return text
    }

    /// `shortcut` as the app keeps it, or nil when the app can't take it.
    func value(_ shortcut: Shortcut) -> ConfigValue? {
        let hotkey = shortcut.hotkey
        let code = Int(hotkey.key.keyCode)
        let mask = hotkey.modifiers.reduce(0) { $0 + (Self.carbonMasks[$1] ?? 0) }
        switch self {
        case .text(let names, let fn, let joiner, let keys, let whole):
            if !whole.isEmpty, let text = whole[Self.shared.text(shortcut) ?? ""] { return .string(text) }
            guard !shortcut.fn || fn != nil,
                let modifiers = Modifier.allCases.filter(hotkey.modifiers.contains).map({ names[$0] }).allPresent()
            else { return nil }
            let held = (shortcut.fn ? fn.map { [$0] } ?? [] : []) + modifiers
            return .string((held + [keys[hotkey.key.name] ?? hotkey.key.name]).joined(separator: joiner))
        case _ where shortcut.fn:
            return nil
        case .carbonJSON:
            return .string("{\"\(JSONKey.keyCode)\":\(code),\"\(JSONKey.modifiers)\":\(mask)}")
        case .carbonTable(let keyCode, let modifiers):
            return .table([keyCode: .integer(code), modifiers: .integer(mask)])
        }
    }
}

/// A shortcut in the shared syntax of the files in dots: a `Hotkey`, with fn held or not, such as
/// `fn+ctrl+f`.
struct Shortcut: Equatable, Sendable {
    /// The word for fn in the shared syntax.
    static let fn = "fn"

    /// The modifiers and the key.
    let hotkey: Hotkey
    /// Whether fn is held too.
    let fn: Bool

    /// The shortcut `text` names: a `Hotkey` in the shared syntax, with `fn` among its modifiers
    /// at most once when fn is held. Nil when it isn't one.
    init?(_ text: String) {
        var words = text.split(separator: Hotkey.joiner, omittingEmptySubsequences: false).map(String.init)
        let held = words.dropLast().filter { $0 == Self.fn }.count
        words.removeAll { $0 == Self.fn && held == 1 }
        guard held <= 1, let hotkey = Hotkey(words.joined(separator: Hotkey.joiner)) else { return nil }
        self.hotkey = hotkey
        self.fn = held == 1
    }
}
