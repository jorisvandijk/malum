import Testing

@testable import MalumCore

/// What the keyboard module logs about keys that don't reach Malum.
extension KeyboardModuleTests {
    @Test func secureInputIsLoggedWhenItStartsAndEnds() async throws {
        let keyboard = module()
        keyboard.apply(settings("[settings]\nhyper_key = \"caps_lock\"\n"))
        try await keyboard.start()
        keyboardState.secureInput = .on(app: "Terminal")
        keyboard.check()
        keyboard.check()
        keyboardState.secureInput = .off
        keyboard.check()
        let blocked = Message.keysBlocked(.secureInput(in: "Terminal"))
        #expect(logWriter.entries.map(\.text).suffix(2) == [blocked.text, Message.keysReachMalumAgain.text])
        #expect(logWriter.entries.filter { $0.text == blocked.text }.count == 1)
    }

    @Test func tapSwitchOffsAreLoggedOnceAtTheNextCheck() async throws {
        let keyboard = module()
        keyboard.apply(settings("[settings]\nhyper_key = \"caps_lock\"\n"))
        try await keyboard.start()
        let session = try #require(catcher.session)
        _ = session.decide(.switchedOff)
        _ = session.decide(.switchedOff)
        keyboard.check()
        keyboard.check()
        let switchedOff = Message.tapSwitchedOffByMacOS(times: 2).text
        #expect(logWriter.entries.filter { $0.text == switchedOff }.count == 1)
        #expect(!logWriter.entries.contains { $0.text == Message.tapSwitchedOffByMacOS(times: 0).text })
    }
}
