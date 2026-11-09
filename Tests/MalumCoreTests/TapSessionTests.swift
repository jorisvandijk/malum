import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TapSessionTests {
    /// The launcher on hyper+space, with caps lock as the hyper key.
    private static let text = """
        hyper_key = "caps_lock"

        [hyper]
        space = "launcher"
        """

    /// What hyper+space runs.
    private let launcher = HotkeyTarget(module: "launcher", action: .module("launcher"))

    /// A session for `text`, with a launcher module.
    private func session() throws -> TapSession {
        let config = try #require(KeyboardConfig.read(Self.text).config)
        let offers = ["launcher": HotkeyOffer(actions: ["launcher"])]
        let registry = HotkeyRegistry(
            bindings: config.bindings, offers: offers, switchedOn: ["launcher"], lines: TOMLLines(Self.text))
        return TapSession(registry: registry, hyperKey: config.hyperKey)
    }

    /// The key `key` going down, or up when `down` is false.
    private func press(_ key: Key, down: Bool = true) -> TapEvent {
        .key(KeyPress(keyCode: key.keyCode, isDown: down, isRepeat: false, modifiers: []))
    }

    /// Every shortcut `session` sent out, once it has ended.
    private func actions(of session: TapSession) async -> [HotkeyTarget] {
        var targets: [HotkeyTarget] = []
        for await target in session.actions {
            targets.append(target)
        }
        return targets
    }

    @Test func shortcutGoesOutOnActions() async throws {
        let session = try session()
        let space = try #require(Key.named("space"))
        #expect(session.decide(press(KeyMapping.hyperTarget)) == .swallow)
        #expect(session.decide(press(space)) == .run(launcher))
        #expect(session.decide(press(space, down: false)) == .swallow)
        _ = session.end()
        #expect(await actions(of: session) == [launcher])
    }

    @Test func passedKeysSendNothing() async throws {
        let session = try session()
        let key = try #require(Key.named("k"))
        #expect(session.decide(press(key)) == .pass)
        #expect(session.end() == .pass)
        #expect(await actions(of: session).isEmpty)
    }

    @Test func endClosesAnOpenSwitcher() throws {
        let session = try session()
        #expect(session.decide(press(KeyMapping.hyperTarget)) == .swallow)
        #expect(session.decide(press(.tab)) == .openSwitcher([.cmd]))
        #expect(session.end() == .closeSwitcher)
    }
}
