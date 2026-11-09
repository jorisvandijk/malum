/// The key mapping Malum hands to `hidutil`: the hyper key typing as F18, then every `[remap]`.
///
/// The event tap tells the hyper key apart because it arrives as F18, a key Mac keyboards lack.
struct KeyMapping: Equatable, Sendable {
    /// One HID usage typing as another.
    struct Entry: Equatable, Sendable {
        /// The usage pressed.
        let source: UInt64
        /// The usage it types as.
        let destination: UInt64
    }

    /// The key the hyper key types as.
    static let hyperTarget = Key.f18
    /// The mapping that undoes every remap.
    static let none = Self(entries: [])

    /// The property `hidutil` sets.
    private static let property = "UserKeyMapping"
    /// The name of an entry's pressed usage.
    private static let sourceName = "HIDKeyboardModifierMappingSrc"
    /// The name of an entry's typed usage.
    private static let destinationName = "HIDKeyboardModifierMappingDst"

    /// Every usage remapped, the hyper key's first.
    let entries: [Entry]

    /// Creates the mapping of `config`'s hyper key and remaps.
    init(_ config: KeyboardConfig) {
        var remaps = config.remaps
        if let hyperKey = config.hyperKey, hyperKey != Self.hyperTarget {
            remaps.insert(KeyRemap(from: hyperKey, to: Self.hyperTarget), at: 0)
        }
        self.init(entries: remaps.flatMap(Self.entries))
    }

    /// Creates the mapping of `entries`.
    private init(entries: [Entry]) {
        self.entries = entries
    }

    /// The property as JSON, such as `{"UserKeyMapping":[]}` for no remaps. The values are only
    /// numbers, so nothing needs escaping.
    var json: String {
        let items = entries.map { entry in
            #"{"\#(Self.sourceName)":\#(entry.source),"\#(Self.destinationName)":\#(entry.destination)}"#
        }
        return #"{"\#(Self.property)":[\#(items.joined(separator: ","))]}"#
    }

    /// Whether one of `swaps`, set per keyboard in System Settings, turns `key` into another key. macOS
    /// applies those before Malum's mapping, so on that keyboard `key` never types as Malum's.
    static func isSwapped(_ key: Key, in swaps: [[String: UInt64]]) -> Bool {
        swaps.contains { swap in
            guard let source = swap[sourceName], let destination = swap[destinationName] else { return false }
            return key.hidUsages.contains(source) && source != destination
        }
    }

    /// The entries of `remap`: every usage the pressed key is sent as, typing as the first usage of
    /// the other.
    private static func entries(_ remap: KeyRemap) -> [Entry] {
        guard let destination = remap.to.hidUsages.first else { return [] }
        return remap.from.hidUsages.map { Entry(source: $0, destination: destination) }
    }
}
