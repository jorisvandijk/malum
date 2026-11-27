/// A key pressed with modifiers held down, such as cmd+h.
struct Hotkey: Hashable, Sendable {
    /// What joins the modifiers and the key in the shared syntax, such as `ctrl+option+k`.
    static let joiner = "+"

    /// The modifiers held down, all four for the hyper key.
    let modifiers: Set<Modifier>
    /// The key pressed.
    let key: Key

    /// Creates the shortcut `key` with `modifiers` held down.
    init(modifiers: Set<Modifier>, key: Key) {
        self.modifiers = modifiers
        self.key = key
    }

    /// The shortcut `text` names in the shared syntax: modifiers (`ctrl`, `option`, `cmd`, `shift`,
    /// or `hyper` for all four), each once, then a key name from `Key`, joined by `+`, such as
    /// `ctrl+option+k`. Nil when it isn't one.
    init?(_ text: String) {
        let words = text.split(separator: Self.joiner, omittingEmptySubsequences: false).map(String.init)
        guard let last = words.last, let key = Key.named(last) else { return nil }
        var modifiers: Set<Modifier> = []
        for word in words.dropLast() {
            let held = word == Modifier.hyper ? Set(Modifier.allCases) : Modifier(rawValue: word).map { [$0] }
            guard let held, modifiers.isDisjoint(with: held) else { return nil }
            modifiers.formUnion(held)
        }
        self.init(modifiers: modifiers, key: key)
    }
}
