/// One key on the keyboard, by the name `keyboard.toml` uses for it, with the codes macOS knows it by.
///
/// The names are one short set with no aliases. The codes are platform constants: the virtual key
/// code is the `kVK_` constant from Carbon's `Events.h` that the event tap sees, and the HID usages
/// are what `hidutil` remaps.
struct Key: Hashable, Sendable {
    /// The HID page of the keyboard's own keys, shifted to where `hidutil` wants it.
    private static let keyboardPage: UInt64 = 0x7_0000_0000

    /// The name, such as `caps_lock`.
    let name: String
    /// The virtual key code, such as `0x39` for caps lock.
    let keyCode: UInt16
    /// The key's HID usages, page included. A key sent on more than one page has each, the first
    /// being the one a remap turns other keys into.
    let hidUsages: [UInt64]
    /// Whether `hyper_key` can be this key.
    let canBeHyper: Bool

    /// Creates the key `name` on the keyboard page, with its virtual key code and its usage on that page.
    private init(_ name: String, keyCode: UInt16, usage: UInt64, canBeHyper: Bool = false) {
        self.init(name, keyCode: keyCode, hidUsages: [Self.keyboardPage + usage], canBeHyper: canBeHyper)
    }

    /// Creates the key `name` with its virtual key code and every HID usage it's sent as.
    private init(_ name: String, keyCode: UInt16, hidUsages: [UInt64], canBeHyper: Bool = false) {
        self.name = name
        self.keyCode = keyCode
        self.hidUsages = hidUsages
        self.canBeHyper = canBeHyper
    }

    /// The key called `name`, or nil when no key is.
    static func named(_ name: String) -> Key? {
        byName[name]
    }

    /// The keys `hyper_key` can be, in the order `all` lists them.
    static var hyperKeys: [Key] { all.filter(\.canBeHyper) }

    /// Every key, by name.
    private static let byName = Dictionary(uniqueKeysWithValues: all.map { ($0.name, $0) })

    // The codes below are platform constants, each named by the key on its row, so a constant per
    // number would only type every name twice.
    // swiftlint:disable no_magic_numbers

    /// fn on the two Apple vendor pages Apple keyboards send it on, depending on the model.
    private static let fnUsages: [UInt64] = [0xFF_0000_0003, 0xFF01_0000_0003]

    /// Every key Malum knows, in the order the docs list them.
    static let all: [Key] = [
        Key("a", keyCode: 0x00, usage: 0x04), Key("b", keyCode: 0x0B, usage: 0x05),
        Key("c", keyCode: 0x08, usage: 0x06), Key("d", keyCode: 0x02, usage: 0x07),
        Key("e", keyCode: 0x0E, usage: 0x08), Key("f", keyCode: 0x03, usage: 0x09),
        Key("g", keyCode: 0x05, usage: 0x0A), Key("h", keyCode: 0x04, usage: 0x0B),
        Key("i", keyCode: 0x22, usage: 0x0C), Key("j", keyCode: 0x26, usage: 0x0D),
        Key("k", keyCode: 0x28, usage: 0x0E), Key("l", keyCode: 0x25, usage: 0x0F),
        Key("m", keyCode: 0x2E, usage: 0x10), Key("n", keyCode: 0x2D, usage: 0x11),
        Key("o", keyCode: 0x1F, usage: 0x12), Key("p", keyCode: 0x23, usage: 0x13),
        Key("q", keyCode: 0x0C, usage: 0x14), Key("r", keyCode: 0x0F, usage: 0x15),
        Key("s", keyCode: 0x01, usage: 0x16), Key("t", keyCode: 0x11, usage: 0x17),
        Key("u", keyCode: 0x20, usage: 0x18), Key("v", keyCode: 0x09, usage: 0x19),
        Key("w", keyCode: 0x0D, usage: 0x1A), Key("x", keyCode: 0x07, usage: 0x1B),
        Key("y", keyCode: 0x10, usage: 0x1C), Key("z", keyCode: 0x06, usage: 0x1D),
        Key("0", keyCode: 0x1D, usage: 0x27), Key("1", keyCode: 0x12, usage: 0x1E),
        Key("2", keyCode: 0x13, usage: 0x1F), Key("3", keyCode: 0x14, usage: 0x20),
        Key("4", keyCode: 0x15, usage: 0x21), Key("5", keyCode: 0x17, usage: 0x22),
        Key("6", keyCode: 0x16, usage: 0x23), Key("7", keyCode: 0x1A, usage: 0x24),
        Key("8", keyCode: 0x1C, usage: 0x25), Key("9", keyCode: 0x19, usage: 0x26),
        Key("f1", keyCode: 0x7A, usage: 0x3A), Key("f2", keyCode: 0x78, usage: 0x3B),
        Key("f3", keyCode: 0x63, usage: 0x3C), Key("f4", keyCode: 0x76, usage: 0x3D),
        Key("f5", keyCode: 0x60, usage: 0x3E), Key("f6", keyCode: 0x61, usage: 0x3F),
        Key("f7", keyCode: 0x62, usage: 0x40), Key("f8", keyCode: 0x64, usage: 0x41),
        Key("f9", keyCode: 0x65, usage: 0x42), Key("f10", keyCode: 0x6D, usage: 0x43),
        Key("f11", keyCode: 0x67, usage: 0x44), Key("f12", keyCode: 0x6F, usage: 0x45),
        Key("f13", keyCode: 0x69, usage: 0x68, canBeHyper: true),
        Key("f14", keyCode: 0x6B, usage: 0x69, canBeHyper: true),
        Key("f15", keyCode: 0x71, usage: 0x6A, canBeHyper: true),
        Key("f16", keyCode: 0x6A, usage: 0x6B, canBeHyper: true),
        Key("f17", keyCode: 0x40, usage: 0x6C, canBeHyper: true),
        Key("f18", keyCode: 0x4F, usage: 0x6D, canBeHyper: true),
        Key("f19", keyCode: 0x50, usage: 0x6E, canBeHyper: true),
        Key("f20", keyCode: 0x5A, usage: 0x6F, canBeHyper: true),
        Key("return", keyCode: 0x24, usage: 0x28), Key("tab", keyCode: 0x30, usage: 0x2B),
        Key("space", keyCode: 0x31, usage: 0x2C), Key("delete", keyCode: 0x33, usage: 0x2A),
        Key("delete_forward", keyCode: 0x75, usage: 0x4C), Key("escape", keyCode: 0x35, usage: 0x29),
        Key("left", keyCode: 0x7B, usage: 0x50), Key("right", keyCode: 0x7C, usage: 0x4F),
        Key("up", keyCode: 0x7E, usage: 0x52), Key("down", keyCode: 0x7D, usage: 0x51),
        Key("home", keyCode: 0x73, usage: 0x4A), Key("end", keyCode: 0x77, usage: 0x4D),
        Key("page_up", keyCode: 0x74, usage: 0x4B), Key("page_down", keyCode: 0x79, usage: 0x4E),
        Key("minus", keyCode: 0x1B, usage: 0x2D), Key("equal", keyCode: 0x18, usage: 0x2E),
        Key("open_bracket", keyCode: 0x21, usage: 0x2F), Key("close_bracket", keyCode: 0x1E, usage: 0x30),
        Key("backslash", keyCode: 0x2A, usage: 0x31), Key("semicolon", keyCode: 0x29, usage: 0x33),
        Key("quote", keyCode: 0x27, usage: 0x34), Key("grave", keyCode: 0x32, usage: 0x35),
        Key("comma", keyCode: 0x2B, usage: 0x36), Key("period", keyCode: 0x2F, usage: 0x37),
        Key("slash", keyCode: 0x2C, usage: 0x38), Key("non_us_backslash", keyCode: 0x0A, usage: 0x64),
        Key("caps_lock", keyCode: 0x39, usage: 0x39, canBeHyper: true),
        Key("fn", keyCode: 0x3F, hidUsages: fnUsages),
        Key("left_control", keyCode: 0x3B, usage: 0xE0), Key("right_control", keyCode: 0x3E, usage: 0xE4),
        Key("left_shift", keyCode: 0x38, usage: 0xE1), Key("right_shift", keyCode: 0x3C, usage: 0xE5),
        Key("left_option", keyCode: 0x3A, usage: 0xE2, canBeHyper: true),
        Key("right_option", keyCode: 0x3D, usage: 0xE6, canBeHyper: true),
        Key("left_command", keyCode: 0x37, usage: 0xE3),
        Key("right_command", keyCode: 0x36, usage: 0xE7, canBeHyper: true),
    ]
    // swiftlint:enable no_magic_numbers
}
