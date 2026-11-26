import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

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

    @Test func actionByNameRunsOnTheRunningModuleThatOffersIt() async throws {
        launcher.hotkeys = HotkeyOffer(actions: ["launcher"])
        routes.add([launcher])
        try await launcher.start()
        #expect(routes.run(actionNamed: "launcher"))
        #expect(!routes.run(actionNamed: "screenshot"))
        #expect(launcher.calls == ["start", "perform module(\"launcher\")"])
    }

    @Test func actionByNameOfAModuleThatDoesNotRunDoesNothing() {
        launcher.hotkeys = HotkeyOffer(actions: ["launcher"])
        routes.add([launcher])
        #expect(!routes.run(actionNamed: "launcher"))
        #expect(launcher.calls.isEmpty)
    }

    @Test func switchOnSaysWhetherAnythingChanged() {
        #expect(routes.switchOn(["launcher"]))
        #expect(!routes.switchOn(["launcher"]))
        #expect(routes.switchedOn == ["launcher"])
    }

    @Test func dragGoesToTheRunningModuleThatTakesDrags() async throws {
        let windows = RecordingModule(id: "window_manager")
        windows.hotkeys = HotkeyOffer(takesDrags: true)
        routes.add([launcher, windows])
        let drag = PointerDrag(.began, at: .zero)
        routes.drag(drag)
        #expect(windows.calls.isEmpty)
        try await launcher.start()
        try await windows.start()
        routes.drag(drag)
        #expect(windows.calls == ["start", "drag \(drag)"])
        #expect(launcher.calls == ["start"])
    }
}
