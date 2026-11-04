import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ModuleSwitchTests {
    private let launcher = RecordingModule(id: "launcher")
    private let screenshots = RecordingModule(id: "screenshots")
    private let keyboard = RecordingModule(id: "keyboard", permissions: [.accessibility, .inputMonitoring])

    private func moduleSwitch(_ permissions: FakePermissions = FakePermissions()) -> ModuleSwitch {
        ModuleSwitch(modules: [launcher, screenshots, keyboard], permissions: permissions)
    }

    @Test func switchedOnModuleGetsItsSettingsThenStarts() async {
        let modules = moduleSwitch()
        let messages = await modules.update(
            enabled: ["launcher"], settings: ["launcher": ["size": .integer(1)], "screenshots": [:]],
            changed: ["launcher", "screenshots"])
        #expect(messages == [Message(.info, "started launcher")])
        #expect(launcher.calls == ["apply size=1", "start"])
        #expect(screenshots.calls.isEmpty)
        #expect(modules.started == ["launcher"])
    }

    @Test func switchedOffModuleStops() async {
        let modules = moduleSwitch()
        _ = await modules.update(enabled: ["launcher"], settings: [:], changed: [])
        let messages = await modules.update(enabled: [], settings: [:], changed: [])
        #expect(messages == [Message(.info, "stopped launcher")])
        #expect(launcher.calls == ["apply ", "start", "stop"])
        #expect(modules.started.isEmpty)
    }

    @Test func runningModuleGetsChangedSettings() async {
        let modules = moduleSwitch()
        _ = await modules.update(enabled: ["launcher"], settings: ["launcher": ["size": .integer(1)]], changed: [])
        let messages = await modules.update(
            enabled: ["launcher"], settings: ["launcher": ["size": .integer(2)]], changed: ["launcher"])
        #expect(messages.isEmpty)
        #expect(launcher.calls == ["apply size=1", "start", "apply size=2"])
    }

    @Test func unchangedRunningModuleIsLeftAlone() async {
        let modules = moduleSwitch()
        _ = await modules.update(enabled: ["launcher"], settings: [:], changed: [])
        let messages = await modules.update(enabled: ["launcher"], settings: [:], changed: ["screenshots"])
        #expect(messages.isEmpty)
        #expect(launcher.calls == ["apply ", "start"])
    }

    @Test func failedStartIsTriedAgainOnlyWhenItsTableChanges() async {
        let modules = moduleSwitch()
        launcher.failsToStart = true
        let failed = await modules.update(enabled: ["launcher"], settings: [:], changed: [])
        #expect(failed == [Message(.error, "couldn't start launcher: it broke")])
        #expect(await modules.update(enabled: ["launcher"], settings: [:], changed: ["screenshots"]).isEmpty)
        launcher.failsToStart = false
        let retried = await modules.update(enabled: ["launcher"], settings: [:], changed: ["launcher"])
        #expect(retried == [Message(.info, "started launcher")])
        #expect(launcher.calls == ["apply ", "start", "apply ", "start"])
    }

    @Test func settingsARunningModuleRefusesAreReported() async {
        let modules = moduleSwitch()
        _ = await modules.update(enabled: ["launcher"], settings: [:], changed: [])
        launcher.failsToApply = true
        let messages = await modules.update(
            enabled: ["launcher"], settings: ["launcher": ["size": .integer(2)]], changed: ["launcher"])
        #expect(messages == [Message(.error, "couldn't apply launcher settings: it broke")])
        #expect(modules.started == ["launcher"])
    }

    @Test func overlappingUpdatesRunInOrder() async {
        let modules = moduleSwitch()
        let first = Task { await modules.update(enabled: ["launcher", "screenshots"], settings: [:], changed: []) }
        let second = Task { await modules.update(enabled: [], settings: [:], changed: []) }
        let messages = await first.value + second.value
        #expect(messages.count == 4)
        #expect(launcher.calls == ["apply ", "start", "stop"])
        #expect(screenshots.calls == ["apply ", "start", "stop"])
        #expect(modules.started.isEmpty)
    }

    @Test func cleanUpRunsForEveryModuleAndReportsFailures() async {
        let modules = moduleSwitch()
        launcher.failsToCleanUp = true
        let messages = await modules.cleanUp()
        #expect(messages == [Message(.warn, "couldn't clean up after launcher: it broke")])
        #expect(launcher.calls == ["clean up"])
        #expect(screenshots.calls == ["clean up"])
    }

    @Test func updateWaitsForCleanUp() async {
        let modules = moduleSwitch()
        async let cleanedUp = modules.cleanUp()
        async let updated = modules.update(enabled: ["launcher"], settings: [:], changed: [])
        _ = await (cleanedUp, updated)
        #expect(launcher.calls == ["clean up", "apply ", "start"])
    }

    @Test func moduleMissingPermissionsWaitsWithoutStarting() async {
        let modules = moduleSwitch(FakePermissions([.accessibility: .missing]))
        let messages = await modules.update(enabled: ["keyboard"], settings: [:], changed: [])
        #expect(messages == [Message(.warn, "couldn't start keyboard yet: it needs Accessibility")])
        #expect(keyboard.calls.isEmpty)
        #expect(modules.waiting == ["keyboard": [.accessibility]])
    }

    @Test func permissionMacOSCantTellAboutDoesntKeepAModuleOff() async {
        let modules = moduleSwitch(FakePermissions([.accessibility: .unknown]))
        let messages = await modules.update(enabled: ["keyboard"], settings: [:], changed: [])
        #expect(messages == [Message(.info, "started keyboard")])
        #expect(modules.waiting.isEmpty)
    }

    @Test func waitingModuleStartsOnceItsPermissionsAreGranted() async {
        let permissions = FakePermissions([.accessibility: .missing])
        let modules = moduleSwitch(permissions)
        _ = await modules.update(enabled: ["keyboard"], settings: ["keyboard": ["size": .integer(3)]], changed: [])
        #expect(await modules.retryWaiting().isEmpty)
        permissions.set(.accessibility, .granted)
        #expect(await modules.retryWaiting() == [Message(.info, "started keyboard")])
        #expect(keyboard.calls == ["apply size=3", "start"])
        #expect(modules.waiting.isEmpty)
    }

    @Test func waitingModuleSaysSoAgainOnlyWhenWhatsMissingChanges() async {
        let permissions = FakePermissions([.accessibility: .missing, .inputMonitoring: .missing])
        let modules = moduleSwitch(permissions)
        _ = await modules.update(enabled: ["keyboard"], settings: [:], changed: [])
        #expect(await modules.update(enabled: ["keyboard"], settings: [:], changed: ["keyboard"]).isEmpty)
        permissions.set(.inputMonitoring, .granted)
        let messages = await modules.retryWaiting()
        #expect(messages == [Message(.warn, "couldn't start keyboard yet: it needs Accessibility")])
        #expect(modules.waiting == ["keyboard": [.accessibility]])
    }

    @Test func switchingAWaitingModuleOffStopsTheWait() async {
        let modules = moduleSwitch(FakePermissions([.accessibility: .missing]))
        _ = await modules.update(enabled: ["keyboard"], settings: [:], changed: [])
        #expect(await modules.update(enabled: [], settings: [:], changed: []).isEmpty)
        #expect(modules.waiting.isEmpty)
        #expect(keyboard.calls.isEmpty)
    }
}
