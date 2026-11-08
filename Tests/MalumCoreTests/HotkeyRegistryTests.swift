import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct HotkeyRegistryTests {
    /// A `keyboard.toml` with a module's action, an app and a cmd shortcut.
    private static let text = """
        [cmd]
        h = "hide_all"

        [hyper]
        f = "com.apple.finder"
        space = "launcher"
        """

    /// The registry for `text` and the modules in `offers`, with those in `switchedOn` running.
    private func registry(
        _ text: String = text, offers: [String: HotkeyOffer], switchedOn: Set<String>? = nil
    ) throws -> HotkeyRegistry {
        let config = try #require(KeyboardConfig.read(text).config)
        return HotkeyRegistry(
            bindings: config.bindings, offers: offers, switchedOn: switchedOn ?? Set(offers.keys),
            lines: TOMLLines(text))
    }

    /// The shortcut `name` with `modifiers`, which the test knows is a key.
    private func hotkey(_ modifiers: Set<Modifier>, _ name: String) throws -> Hotkey {
        Hotkey(modifiers: modifiers, key: try #require(Key.named(name)))
    }

    /// Every modifier, which the hyper key holds.
    private let hyper = Set(Modifier.allCases)

    /// The offers of a launcher and a window manager that opens apps and hides with cmd+h.
    private func offers() throws -> [String: HotkeyOffer] {
        [
            "launcher": HotkeyOffer(actions: ["launcher"]),
            "window_manager": HotkeyOffer(
                actions: ["hide_all"], fixedKeys: [try hotkey([.cmd], "m"): "minimize"], opensApps: true),
        ]
    }

    @Test func bindingGoesToTheModuleThatOffersItsAction() throws {
        let registry = try registry(offers: offers())
        #expect(
            registry.target(for: try hotkey(hyper, "space"))
                == HotkeyTarget(module: "launcher", action: .module("launcher")))
        #expect(registry.problems.isEmpty)
    }

    @Test func appBindingGoesToTheModuleThatOpensApps() throws {
        let registry = try registry(offers: offers())
        #expect(
            registry.target(for: try hotkey(hyper, "f"))
                == HotkeyTarget(module: "window_manager", action: .app("com.apple.finder")))
    }

    @Test func fixedKeyGoesToItsModule() throws {
        let registry = try registry(offers: offers())
        #expect(
            registry.target(for: try hotkey([.cmd], "m"))
                == HotkeyTarget(module: "window_manager", action: .module("minimize")))
    }

    @Test func keyNothingHasHasNoTarget() throws {
        let registry = try registry(offers: offers())
        #expect(registry.target(for: try hotkey(hyper, "z")) == nil)
    }

    @Test func bindingOnAFixedKeyIsAnErrorAtItsLine() throws {
        let registry = try registry("[cmd]\nm = \"launcher\"\n", offers: offers())
        #expect(
            registry.problems == [
                ConfigProblem(.error, file: "keyboard.toml", line: 2, "cmd.m: cmd+m is taken by window_manager")
            ])
        #expect(registry.target(for: try hotkey([.cmd], "m"))?.module == "window_manager")
    }

    @Test func actionNoModuleOffersIsAnErrorAtItsLine() throws {
        let registry = try registry("[hyper]\nh = \"clipboard_history\"\n", offers: offers())
        #expect(
            registry.problems == [
                ConfigProblem(.error, file: "keyboard.toml", line: 2, "hyper.h: no module offers clipboard_history")
            ])
        #expect(registry.target(for: try hotkey(hyper, "h")) == nil)
    }

    @Test func switchedOffModuleWarnsOnceAndGetsNoKeys() throws {
        let text = "[hyper]\nl = \"launcher\"\nspace = \"launcher\"\n"
        let registry = try registry(text, offers: offers(), switchedOn: ["window_manager"])
        #expect(
            registry.problems == [
                ConfigProblem(.warn, file: "keyboard.toml", line: 2, "launcher is switched off, so its keys do nothing")
            ])
        #expect(registry.target(for: try hotkey(hyper, "space")) == nil)
    }

    @Test func fixedKeyOfASwitchedOffModuleIsFree() throws {
        let registry = try registry("[cmd]\nm = \"launcher\"\n", offers: offers(), switchedOn: ["launcher"])
        #expect(registry.target(for: try hotkey([.cmd], "m"))?.module == "launcher")
        #expect(registry.problems.isEmpty)
    }

    @Test func appsWithNoModuleToOpenThemWarnOnce() throws {
        let text = "[hyper]\nb = \"com.bitwarden.desktop\"\nf = \"com.apple.finder\"\n"
        let registry = try registry(text, offers: ["launcher": HotkeyOffer(actions: ["launcher"])])
        #expect(
            registry.problems == [
                ConfigProblem(
                    .warn, file: "keyboard.toml", line: 2,
                    "no module opens apps yet, so the keys bound to apps do nothing")
            ])
        #expect(registry.target(for: try hotkey(hyper, "f")) == nil)
    }

    @Test func actionOfferedTwiceStaysWithTheFirstModule() throws {
        let registry = try registry(
            offers: ["launcher": HotkeyOffer(actions: ["launcher"]), "other": HotkeyOffer(actions: ["launcher"])],
            switchedOn: ["launcher", "other"])
        #expect(
            registry.problems.contains(
                ConfigProblem(
                    .error, file: "keyboard.toml", "launcher and other both claim launcher, so other doesn't get it")))
        #expect(registry.target(for: try hotkey(hyper, "space"))?.module == "launcher")
    }

    @Test func fixedKeyClaimedTwiceStaysWithTheFirstModule() throws {
        let cmdM = try hotkey([.cmd], "m")
        let registry = try registry(
            "",
            offers: [
                "a_module": HotkeyOffer(fixedKeys: [cmdM: "one"]), "b_module": HotkeyOffer(fixedKeys: [cmdM: "two"]),
            ])
        #expect(
            registry.problems
                == [
                    ConfigProblem(
                        .error, file: "keyboard.toml",
                        "a_module and b_module both claim cmd+m, so b_module doesn't get it")
                ])
        #expect(registry.target(for: cmdM) == HotkeyTarget(module: "a_module", action: .module("one")))
    }
}
