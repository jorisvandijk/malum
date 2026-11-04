import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ModuleSwitchTests {
    private let launcher = RecordingModule(id: "launcher")
    private let screenshots = RecordingModule(id: "screenshots")

    private func moduleSwitch() -> ModuleSwitch {
        ModuleSwitch(modules: [launcher, screenshots])
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
}
