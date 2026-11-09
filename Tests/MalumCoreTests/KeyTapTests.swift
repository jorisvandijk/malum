import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyTapTests {
    /// The longest one decision may take on average: the tap callback's budget.
    private static let budget = Duration.milliseconds(1)

    /// A `keyboard.toml` with a module's action on hyper, one on ctrl+shift, and an app.
    private static let text = """
        hyper_key = "caps_lock"

        [ctrl_shift]
        v = "clipboard_history"

        [hyper]
        f = "com.apple.finder"
        space = "launcher"
        """

    /// Every modifier, which the hyper key holds.
    private let hyper = Set(Modifier.allCases)

    /// The tap for `text`, with a launcher and clipboard history and no module that opens apps.
    private func tap(_ text: String = text) throws -> KeyTap {
        let config = try #require(KeyboardConfig.read(text).config)
        let offers = [
            "launcher": HotkeyOffer(actions: ["launcher"]),
            "clipboard_history": HotkeyOffer(actions: ["clipboard_history"]),
        ]
        let registry = HotkeyRegistry(
            bindings: config.bindings, offers: offers, switchedOn: Set(offers.keys), lines: TOMLLines(text))
        return KeyTap(registry: registry, hyperKey: config.hyperKey)
    }

    /// What `tap` decides for each of `events`, checking they took no longer than the budget on average.
    private func decisions(_ events: [TapEvent], from tap: KeyTap? = nil) throws -> [TapDecision] {
        var tap = try tap ?? self.tap()
        var decisions: [TapDecision] = []
        let elapsed = ContinuousClock().measure {
            decisions = events.map { tap.decide($0) }
        }
        #expect(elapsed < Self.budget * events.count)
        return decisions
    }

    /// The key called `name` going down, or up when `down` is false.
    private func key(
        _ name: String, down: Bool = true, repeating: Bool = false, held modifiers: Set<Modifier> = []
    ) throws -> TapEvent {
        let key = try #require(Key.named(name))
        return .key(KeyPress(keyCode: key.keyCode, isDown: down, isRepeat: repeating, modifiers: modifiers))
    }

    /// The hyper key, as it arrives after the remap, going down or up.
    private func hyperKey(down: Bool) -> TapEvent {
        .key(KeyPress(keyCode: KeyMapping.hyperTarget.keyCode, isDown: down, isRepeat: false, modifiers: []))
    }

    @Test func hyperKeyIsSwallowed() throws {
        #expect(try decisions([hyperKey(down: true), hyperKey(down: false)]) == [.swallow, .swallow])
    }

    @Test func keyWithHyperHeldGetsAllFourModifiers() throws {
        let events = [hyperKey(down: true), try key("k"), try key("k", down: false), hyperKey(down: false)]
        #expect(try decisions(events) == [.swallow, .passAs(hyper), .passAs(hyper), .swallow])
    }

    @Test func keyAfterHyperLetGoPassesAsItIs() throws {
        let events = [hyperKey(down: true), hyperKey(down: false), try key("k"), try key("k", down: false)]
        #expect(try decisions(events) == [.swallow, .swallow, .pass, .pass])
    }

    @Test func boundKeyRunsItsActionOnceAndSwallowsItsRepeatsAndKeyUp() throws {
        let target = HotkeyTarget(module: "launcher", action: .module("launcher"))
        let events = [
            hyperKey(down: true), try key("space"), try key("space", repeating: true),
            try key("space", repeating: true),
            try key("space", down: false), hyperKey(down: false),
        ]
        #expect(try decisions(events) == [.swallow, .run(target), .swallow, .swallow, .swallow, .swallow])
    }

    @Test func boundKeyUpAfterHyperLetGoIsStillSwallowed() throws {
        let target = HotkeyTarget(module: "launcher", action: .module("launcher"))
        let events = [hyperKey(down: true), try key("space"), hyperKey(down: false), try key("space", down: false)]
        #expect(try decisions(events) == [.swallow, .run(target), .swallow, .swallow])
    }

    @Test func repeatOfABoundKeyHeldBeforeHyperDoesNotRun() throws {
        let events = [try key("space"), hyperKey(down: true), try key("space", repeating: true)]
        #expect(try decisions(events) == [.pass, .swallow, .swallow])
    }

    @Test func appNothingOpensPassesAsAHyperCombination() throws {
        let events = [hyperKey(down: true), try key("f"), try key("f", down: false)]
        #expect(try decisions(events) == [.swallow, .passAs(hyper), .passAs(hyper)])
    }

    @Test func otherModifierTableRunsItsAction() throws {
        let target = HotkeyTarget(module: "clipboard_history", action: .module("clipboard_history"))
        let events = [try key("v", held: [.ctrl, .shift]), try key("v", down: false, held: [.ctrl, .shift])]
        #expect(try decisions(events) == [.run(target), .swallow])
    }

    @Test func unboundModifiersPassAsTheyAre() throws {
        let events = [try key("v", held: [.ctrl]), try key("v", down: false, held: [.ctrl])]
        #expect(try decisions(events) == [.pass, .pass])
    }

    @Test func keyOutsideTheTableWithHyperHeldGetsAllFourModifiers() throws {
        let outside = TapEvent.key(KeyPress(keyCode: .max, isDown: true, isRepeat: false, modifiers: []))
        #expect(try decisions([hyperKey(down: true), outside]) == [.swallow, .passAs(hyper)])
    }

    @Test func f18WithoutAHyperKeyIsAKeyOfItsOwn() throws {
        #expect(try decisions([hyperKey(down: true)], from: tap("")) == [.pass])
    }

    @Test func hyperTabOpensTheSwitcherUntilHyperIsLetGo() throws {
        let events = [
            hyperKey(down: true), try key("tab"), try key("tab", repeating: true), try key("tab", down: false),
            try key("tab"), try key("tab", down: false), hyperKey(down: false),
        ]
        let decisions = try decisions(events)
        #expect(
            decisions == [
                .swallow, .openSwitcher([.cmd]), .swallow, .swallow, .passAs([.cmd]), .passAs([.cmd]), .closeSwitcher,
            ])
    }

    @Test func shiftGoesBackThroughTheSwitcher() throws {
        let events = [
            hyperKey(down: true), try key("tab", held: [.shift]), .modifiersChanged([.shift]),
            try key("tab", held: [.shift]),
        ]
        let decisions = try decisions(events)
        #expect(
            decisions == [.swallow, .openSwitcher([.cmd, .shift]), .passAs([.cmd, .shift]), .passAs([.cmd, .shift])])
    }

    @Test func modifierChangeWithoutTheSwitcherPassesAsItIs() throws {
        #expect(try decisions([hyperKey(down: true), .modifiersChanged([.shift])]) == [.swallow, .pass])
    }

    @Test func bindingStillRunsWhileTheSwitcherIsOpen() throws {
        let target = HotkeyTarget(module: "launcher", action: .module("launcher"))
        let events = [hyperKey(down: true), try key("tab"), try key("space")]
        #expect(try decisions(events) == [.swallow, .openSwitcher([.cmd]), .run(target)])
    }

    @Test func switchedOffStartsOverWithHyperLetGo() throws {
        let events = [hyperKey(down: true), .switchedOff, try key("k")]
        #expect(try decisions(events) == [.swallow, .pass, .pass])
    }

    @Test func switchedOffClosesAnOpenSwitcher() throws {
        let events = [hyperKey(down: true), try key("tab"), .switchedOff, try key("k")]
        #expect(try decisions(events) == [.swallow, .openSwitcher([.cmd]), .closeSwitcher, .pass])
    }

    @Test func switchedOffForgetsSwallowedKeys() throws {
        let target = HotkeyTarget(module: "launcher", action: .module("launcher"))
        let events = [hyperKey(down: true), try key("space"), .switchedOff, try key("space", down: false)]
        #expect(try decisions(events) == [.swallow, .run(target), .pass, .pass])
    }

    @Test func manyEventsStayWithinTheBudget() throws {
        let press = [hyperKey(down: true), try key("space"), try key("space", down: false), try key("k")]
        let events = Array(repeating: press + [try key("k", down: false), hyperKey(down: false)], count: 10_000)
        #expect(try decisions(events.flatMap { $0 }).count == 60_000)
    }
}
