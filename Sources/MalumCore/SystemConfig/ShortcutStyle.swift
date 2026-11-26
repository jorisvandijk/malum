/// How an app keeps a shortcut, so the shared syntax in dots, such as `ctrl+option+k`, becomes
/// what each app reads.
enum ShortcutStyle: Equatable, Sendable {
    /// Text: the modifiers by `names`, in `Modifier`'s order, then the key's name, joined by
    /// `joiner`, such as kitty's `ctrl+alt+k`.
    case text(names: [Modifier: String], joiner: String)
    /// The Carbon key code and modifiers as JSON text, as apps built with KeyboardShortcuts keep
    /// them: `{"carbonKeyCode":40,"carbonModifiers":6144}`.
    case carbonJSON
    /// A table of the Carbon key code under `keyCode` and the modifiers under `modifiers`.
    case carbonTable(keyCode: String, modifiers: String)

    /// The shared syntax itself, for an app that reads it as it is.
    static let shared = text(
        names: Dictionary(uniqueKeysWithValues: Modifier.allCases.map { ($0, $0.rawValue) }), joiner: Hotkey.joiner)

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

    /// `hotkey` as the app keeps it.
    func value(_ hotkey: Hotkey) -> ConfigValue {
        let code = Int(hotkey.key.keyCode)
        let mask = hotkey.modifiers.reduce(0) { $0 + (Self.carbonMasks[$1] ?? 0) }
        switch self {
        case .text(let names, let joiner):
            let modifiers = Modifier.allCases.filter(hotkey.modifiers.contains).compactMap { names[$0] }
            return .string((modifiers + [hotkey.key.name]).joined(separator: joiner))
        case .carbonJSON:
            return .string("{\"\(JSONKey.keyCode)\":\(code),\"\(JSONKey.modifiers)\":\(mask)}")
        case .carbonTable(let keyCode, let modifiers):
            return .table([keyCode: .integer(code), modifiers: .integer(mask)])
        }
    }
}
