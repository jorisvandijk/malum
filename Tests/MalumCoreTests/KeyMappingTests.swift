import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyMappingTests {
    /// The key called `name`, which the test knows is one.
    private func key(_ name: String) throws -> Key {
        try #require(Key.named(name))
    }

    @Test func noHyperKeyAndNoRemapsIsNone() {
        #expect(KeyMapping(KeyboardConfig()) == .none)
        #expect(KeyMapping.none.json == #"{"UserKeyMapping":[]}"#)
    }

    @Test func hyperKeyTypesAsF18() throws {
        let mapping = KeyMapping(KeyboardConfig(hyperKey: try key("caps_lock")))
        let entry = #"{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771181}"#
        #expect(mapping.json == #"{"UserKeyMapping":["# + entry + "]}")
    }

    @Test func f18AsHyperKeyNeedsNoRemap() {
        #expect(KeyMapping(KeyboardConfig(hyperKey: Key.f18)) == .none)
    }

    @Test func hyperKeyComesBeforeRemaps() throws {
        let remap = KeyRemap(from: try key("grave"), to: try key("delete_forward"))
        let mapping = KeyMapping(KeyboardConfig(hyperKey: try key("caps_lock"), remaps: [remap]))
        #expect(
            mapping.entries == [
                KeyMapping.Entry(source: 0x7_0000_0039, destination: 0x7_0000_006D),
                KeyMapping.Entry(source: 0x7_0000_0035, destination: 0x7_0000_004C),
            ])
    }

    @Test func fnIsRemappedOnBothPages() throws {
        let remap = KeyRemap(from: try key("fn"), to: try key("left_control"))
        #expect(
            KeyMapping(KeyboardConfig(remaps: [remap])).entries == [
                KeyMapping.Entry(source: 0xFF_0000_0003, destination: 0x7_0000_00E0),
                KeyMapping.Entry(source: 0xFF01_0000_0003, destination: 0x7_0000_00E0),
            ])
    }

    @Test func remapToFnTypesAsItsFirstPage() throws {
        let remap = KeyRemap(from: try key("left_control"), to: try key("fn"))
        #expect(
            KeyMapping(KeyboardConfig(remaps: [remap])).entries == [
                KeyMapping.Entry(source: 0x7_0000_00E0, destination: 0xFF_0000_0003)
            ])
    }

    /// A Modifier Keys swap of `from` to `to`, as macOS keeps it.
    private func swap(_ from: String, to: String) throws -> [String: UInt64] {
        [
            "HIDKeyboardModifierMappingSrc": try #require(try key(from).hidUsages.first),
            "HIDKeyboardModifierMappingDst": try #require(try key(to).hidUsages.first),
        ]
    }

    @Test func swapOfTheKeyOnAnyKeyboardCounts() throws {
        let swaps = [try swap("left_control", to: "left_control"), try swap("caps_lock", to: "escape")]
        #expect(KeyMapping.isSwapped(try key("caps_lock"), in: swaps))
        #expect(!KeyMapping.isSwapped(try key("left_control"), in: swaps))
    }

    @Test func swapToItselfOrHalfWrittenDoesntCount() throws {
        let halfWritten = try swap("caps_lock", to: "escape").filter { $0.key == "HIDKeyboardModifierMappingSrc" }
        let swaps = [try swap("caps_lock", to: "caps_lock"), halfWritten]
        #expect(!KeyMapping.isSwapped(try key("caps_lock"), in: swaps))
    }
}
