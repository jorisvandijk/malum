import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyboardConfigTests {
    /// The key called `name`, which the test knows is one.
    private func key(_ name: String) throws -> Key {
        try #require(Key.named(name))
    }

    @Test func exampleLayoutIsRead() throws {
        let reading = KeyboardConfig.read(
            """
            hyper_key = "caps_lock"

            [remap]
            grave = "delete_forward"
            fn = "left_control"

            [hyper]
            f = "com.apple.finder"
            space = "launcher"

            [ctrl_shift]
            return = "net.kovidgoyal.kitty"
            """)
        let hyper = Set(Modifier.allCases)
        let expected = KeyboardConfig(
            hyperKey: try key("caps_lock"),
            remaps: [
                KeyRemap(from: try key("fn"), to: try key("left_control")),
                KeyRemap(from: try key("grave"), to: try key("delete_forward")),
            ],
            bindings: [
                KeyBinding(
                    hotkey: Hotkey(modifiers: [.ctrl, .shift], key: try key("return")),
                    action: .app("net.kovidgoyal.kitty")),
                KeyBinding(hotkey: Hotkey(modifiers: hyper, key: try key("f")), action: .app("com.apple.finder")),
                KeyBinding(hotkey: Hotkey(modifiers: hyper, key: try key("space")), action: .module("launcher")),
            ])
        #expect(reading.config == expected)
        #expect(reading.problems.isEmpty)
    }

    @Test func emptyFileHasNoHyperKeyAndNoShortcuts() {
        let reading = KeyboardConfig.read("")
        #expect(reading.config == KeyboardConfig())
        #expect(reading.problems.isEmpty)
    }

    @Test func syntaxErrorStopsTheRead() {
        let reading = KeyboardConfig.read("[hyper\n")
        #expect(reading.config == nil)
        #expect(reading.problems.first?.file == "keyboard.toml")
        #expect(reading.problems.first?.line == 1)
    }

    @Test func hyperKeyThatCantBeOneIsAnError() {
        let reading = KeyboardConfig.read("hyper_key = \"a\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    """
                    keyboard.toml line 1: hyper_key should be one of "f13", "f14", "f15", "f16", "f17", "f18", \
                    "f19", "f20", "caps_lock", "left_option", "right_option", "right_command"
                    """)
            ])
    }

    @Test func tableInAnotherOrderNamesTheRightSpelling() {
        let reading = KeyboardConfig.read(
            "[shift_ctrl]\na = \"launcher\"\n\n[cmd_shift_option_ctrl]\nb = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "keyboard.toml line 1: shift_ctrl should be written ctrl_shift"),
                Message(.error, "keyboard.toml line 4: cmd_shift_option_ctrl should be written hyper"),
            ])
    }

    @Test func unknownTableIsOnlyAWarning() {
        let reading = KeyboardConfig.read("[hyper]\na = \"launcher\"\n\n[control]\nb = \"launcher\"\n")
        #expect(reading.config?.bindings.count == 1)
        #expect(reading.problems.map(\.message) == [Message(.warn, "keyboard.toml line 4: unknown table control")])
    }

    @Test func unknownKeyNamesAreErrorsAtTheirLines() {
        let reading = KeyboardConfig.read("[remap]\nenter = \"tab\"\ngrave = \"bksp\"\n\n[hyper]\nesc = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "keyboard.toml line 2: remap.enter: enter isn't a key name"),
                Message(.error, "keyboard.toml line 3: remap.grave should be a key name, such as \"caps_lock\""),
                Message(.error, "keyboard.toml line 6: hyper.esc: esc isn't a key name"),
            ])
    }

    @Test func remappingTheHyperKeyIsAnError() {
        let reading = KeyboardConfig.read("hyper_key = \"caps_lock\"\n\n[remap]\ncaps_lock = \"escape\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    "keyboard.toml line 4: remap.caps_lock: caps_lock is the hyper key, so it can't be remapped too")
            ])
    }

    @Test func actionThatIsntTextOrIsEmptyIsAnError() {
        let reading = KeyboardConfig.read("[hyper]\na = 3\nb = \"\"\nc = \"com.example app\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    "keyboard.toml line 2: hyper.a should be an app's bundle ID or a module's action, such as \"launcher\""
                ),
                Message(
                    .error,
                    "keyboard.toml line 3: hyper.b should be an app's bundle ID or a module's action, such as \"launcher\""
                ),
                Message(.error, "keyboard.toml line 4: hyper.c: a bundle ID can't be empty or hold spaces"),
            ])
    }

    @Test func modifierTableThatIsntATableIsAnError() {
        let reading = KeyboardConfig.read("hyper = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(reading.problems.map(\.message) == [Message(.error, "keyboard.toml line 1: hyper should be a table")])
    }
}
