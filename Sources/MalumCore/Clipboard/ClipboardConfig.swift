/// What the clipboard history's settings ask for, from `clipboard.toml` or the `[clipboard]` table
/// in `malum.toml`.
struct ClipboardConfig: Equatable, Sendable {
    /// The module's id, which names its table, its file and its action.
    static let module = "clipboard"
    /// The key of how many entries are kept.
    private static let sizeKey = "size"
    /// The key of whether picking an entry pastes it.
    private static let pasteKey = "paste"
    /// How many entries are kept when nothing is set.
    static let defaultSize = 300

    /// The clipboard history's settings.
    static let schema = ConfigSchema(
        about: "A history of what you copy, in the popup. See [clipboard history](clipboard.md).",
        settings: [
            sizeKey: Setting(
                .integer, "How many copies the history keeps, at least 1.", default: .integer(defaultSize)),
            pasteKey: Setting(
                .boolean, "Pastes an entry into the app below when you pick it, besides putting it on the clipboard.",
                default: .boolean(true)),
        ])

    /// How many entries are kept.
    let size: Int
    /// Whether picking an entry pastes it.
    let pastes: Bool

    /// Creates a config, by default the one used when nothing is set.
    init(size: Int = defaultSize, pastes: Bool = true) {
        self.size = max(size, 1)
        self.pastes = pastes
    }

    /// Reads `table`, whose kinds `schema` has checked.
    static func read(_ table: ConfigTable) -> Self {
        var size = defaultSize
        if case .integer(let set)? = table[sizeKey] { size = set }
        return Self(size: size, pastes: table[pasteKey] != .boolean(false))
    }
}
