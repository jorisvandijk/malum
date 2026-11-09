import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ModuleRoutesTests {
    private let launcher = RecordingModule(id: "launcher")
    private let routes = ModuleRoutes()

    /// What hyper+space runs.
    private let target = HotkeyTarget(module: "launcher", action: .module("launcher"))

    @Test func offersComeFromEveryModule() {
        launcher.hotkeys = HotkeyOffer(actions: ["launcher"])
        let screenshots = RecordingModule(id: "screenshots")
        routes.add([launcher, screenshots])
        #expect(routes.offers["launcher"]?.actions == ["launcher"])
        #expect(routes.offers["screenshots"]?.actions == [])
    }

    @Test func moduleNothingElseHoldsIsLetGo() {
        routes.add([RecordingModule(id: "screenshots")])
        #expect(routes.offers.isEmpty)
    }

    @Test func shortcutRunsOnARunningModule() async throws {
        routes.add([launcher])
        try await launcher.start()
        routes.run(target)
        #expect(launcher.calls == ["start", "perform module(\"launcher\")"])
    }

    @Test func shortcutForAModuleThatDoesNotRunDoesNothing() {
        routes.add([launcher])
        routes.run(target)
        #expect(launcher.calls.isEmpty)
    }

    @Test func shortcutForAnUnknownModuleDoesNothing() {
        routes.run(target)
        #expect(routes.offers.isEmpty)
    }

    @Test func switchOnSaysWhetherAnythingChanged() {
        #expect(routes.switchOn(["launcher"]))
        #expect(!routes.switchOn(["launcher"]))
        #expect(routes.switchedOn == ["launcher"])
    }
}
