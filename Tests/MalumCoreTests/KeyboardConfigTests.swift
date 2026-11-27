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
            [hyper]
            key = "caps_lock"

            [remaps]
            grave = "delete_forward"
            fn = "left_control"

            [shortcuts]
            "hyper+f" = "com.apple.finder"
            "hyper+space" = "launcher"
            "shift+ctrl+return" = "net.kovidgoyal.kitty"
            """)
        let hyper = Set(Modifier.allCases)
        let expected = KeyboardConfig(
            hyperKey: try key("caps_lock"),
            remaps: [
                KeyRemap(from: try key("fn"), to: try key("left_control")),
                KeyRemap(from: try key("grave"), to: try key("delete_forward")),
            ],
            bindings: [
                KeyBinding(hotkey: Hotkey(modifiers: hyper, key: try key("f")), action: .app("com.apple.finder")),
                KeyBinding(hotkey: Hotkey(modifiers: hyper, key: try key("space")), action: .module("launcher")),
                KeyBinding(
                    hotkey: Hotkey(modifiers: [.ctrl, .shift], key: try key("return")),
                    action: .app("net.kovidgoyal.kitty"), written: "shift+ctrl+return"),
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
        let reading = KeyboardConfig.read("[hyper]\nkey = \"a\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    """
                    keyboard.toml line 2: hyper.key should be "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", \
                    "caps_lock", "left_option", "right_option" or "right_command"
                    """)
            ])
    }

    @Test func shortcutThatIsntOneIsAnError() {
        let reading = KeyboardConfig.read(
            "[shortcuts]\n\"ctrl+\" = \"launcher\"\n\"super+a\" = \"launcher\"\n\"ctrl+ctrl+a\" = \"launcher\"\n")
        #expect(reading.config == nil)
        let shortcut = "a shortcut is modifiers and a key name joined by +, such as \"hyper+b\" or \"ctrl+cmd+h\""
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "keyboard.toml line 2: shortcuts.\"ctrl+\": \(shortcut)"),
                Message(.error, "keyboard.toml line 3: shortcuts.\"super+a\": \(shortcut)"),
                Message(.error, "keyboard.toml line 4: shortcuts.\"ctrl+ctrl+a\": \(shortcut)"),
            ])
    }

    @Test func shortcutWrittenTwiceIsAnError() {
        let reading = KeyboardConfig.read(
            "[shortcuts]\n\"ctrl+cmd+h\" = \"clipboard\"\n\"cmd+ctrl+h\" = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    """
                    keyboard.toml line 2: shortcuts."ctrl+cmd+h" sets the same setting as shortcuts."cmd+ctrl+h", \
                    to something else
                    """)
            ])
    }

    @Test func unknownTablesAndKeysAreOnlyWarnings() {
        let reading = KeyboardConfig.read(
            "[shortcuts]\n\"hyper+a\" = \"launcher\"\n\n[ctrl]\nb = \"launcher\"\n\n[hyper]\nside = \"left\"\n")
        #expect(reading.config?.bindings.count == 1)
        #expect(
            reading.problems.map(\.message) == [
                Message(.warn, "keyboard.toml line 4: unknown table ctrl"),
                Message(.warn, "keyboard.toml line 8: unknown setting hyper.side"),
            ])
    }

    @Test func unknownKeyNamesAreErrorsAtTheirLines() {
        let reading = KeyboardConfig.read(
            "[remaps]\nenter = \"tab\"\ngrave = \"bksp\"\n\n[shortcuts]\n\"hyper+esc\" = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "keyboard.toml line 2: remaps.enter: enter isn't a key name"),
                Message(.error, "keyboard.toml line 3: remaps.grave should be a key name, such as \"caps_lock\""),
                Message(
                    .error,
                    """
                    keyboard.toml line 6: shortcuts."hyper+esc": a shortcut is modifiers and a key name joined by +, \
                    such as "hyper+b" or "ctrl+cmd+h"
                    """),
            ])
    }

    @Test func remappingTheHyperKeyIsAnError() {
        let reading = KeyboardConfig.read("[hyper]\nkey = \"caps_lock\"\n\n[remaps]\ncaps_lock = \"escape\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error,
                    "keyboard.toml line 5: remaps.caps_lock: caps_lock is the hyper key, so it can't be remapped too")
            ])
    }

    @Test func actionThatIsntTextOrIsEmptyIsAnError() {
        let reading = KeyboardConfig.read(
            "[shortcuts]\n\"hyper+a\" = 3\n\"hyper+b\" = \"\"\n\"hyper+c\" = \"com.example app\"\n")
        #expect(reading.config == nil)
        let action = "should be an app's bundle ID or a module's action, such as \"launcher\""
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "keyboard.toml line 2: shortcuts.\"hyper+a\" \(action)"),
                Message(.error, "keyboard.toml line 3: shortcuts.\"hyper+b\" \(action)"),
                Message(
                    .error, "keyboard.toml line 4: shortcuts.\"hyper+c\": a bundle ID can't be empty or hold spaces"),
            ])
    }

    @Test func oldLayoutIsUnknown() {
        let reading = KeyboardConfig.read("[settings]\nhyper_key = \"caps_lock\"\n\n[remap]\ngrave = \"tab\"\n")
        #expect(reading.config == KeyboardConfig())
        #expect(
            reading.problems.map(\.message) == [
                Message(.warn, "keyboard.toml line 1: unknown table settings"),
                Message(.warn, "keyboard.toml line 4: unknown table remap"),
            ])
    }

    @Test func tableThatIsntATableIsAnError() {
        let reading = KeyboardConfig.read("shortcuts = \"launcher\"\n")
        #expect(reading.config == nil)
        #expect(
            reading.problems.map(\.message) == [Message(.error, "keyboard.toml line 1: shortcuts should be a table")])
    }
}
