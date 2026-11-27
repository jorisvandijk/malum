import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct TapSessionTests {
    /// The launcher on hyper+space, with caps lock as the hyper key.
    private static let text = """
        [hyper]
        key = "caps_lock"

        [shortcuts]
        "hyper+space" = "launcher"
        """

    /// What hyper+space runs.
    private let launcher = HotkeyTarget(module: "launcher", action: .module("launcher"))

    /// A session for `text`, with a launcher module.
    private func session() throws -> TapSession {
        let config = try #require(KeyboardConfig.read(Self.text).config)
        let offers = [
            "launcher": HotkeyOffer(actions: ["launcher"]), "window_manager": HotkeyOffer(takesDrags: true),
        ]
        let registry = HotkeyRegistry(
            bindings: config.bindings, offers: offers, switchedOn: Set(offers.keys), lines: TOMLLines(Self.text))
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

    @Test func endedSessionPassesEveryEvent() throws {
        let session = try session()
        #expect(session.decide(press(KeyMapping.hyperTarget)) == .swallow)
        #expect(session.end() == .pass)
        #expect(session.decide(press(.tab)) == .pass)
        #expect(session.end() == .pass)
    }
}

// MARK: - Hyper drags

extension TapSessionTests {
    /// Every drag `session` sent out, once it has ended.
    private func drags(of session: TapSession) async -> [PointerDrag] {
        var drags: [PointerDrag] = []
        for await drag in session.drags {
            drags.append(drag)
        }
        return drags
    }

    @Test func hyperDragGoesOutOnDrags() async throws {
        let session = try session()
        let began = PointerDrag(.began, at: CGPoint(x: 10, y: 20))
        let ended = PointerDrag(.ended, at: CGPoint(x: 30, y: 20))
        #expect(session.decide(press(KeyMapping.hyperTarget)) == .swallow)
        #expect(session.decide(.pointer(began)) == .drag(began))
        #expect(session.decide(.pointer(ended)) == .drag(ended))
        _ = session.end()
        #expect(await drags(of: session) == [began, ended])
        #expect(await actions(of: session).isEmpty)
    }

    @Test func endEndsARunningDrag() async throws {
        let session = try session()
        let began = PointerDrag(.began, at: CGPoint(x: 10, y: 20))
        _ = session.decide(press(KeyMapping.hyperTarget))
        _ = session.decide(.pointer(began))
        #expect(session.end() == .drag(PointerDrag(.ended, at: began.location)))
        #expect(await drags(of: session) == [began, PointerDrag(.ended, at: began.location)])
    }
}
