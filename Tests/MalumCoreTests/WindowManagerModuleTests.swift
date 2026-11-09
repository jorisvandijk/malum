import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct WindowManagerModuleTests {
    /// A 1512 by 982 screen with a 25 point menu bar and the Dock hidden, in AppKit's coordinates.
    private let screen = ScreenRects(
        full: CGRect(x: 0, y: 0, width: 1512, height: 982), visible: CGRect(x: 0, y: 0, width: 1512, height: 957))
    /// The part below the menu bar, in Accessibility's coordinates.
    private let visibleArea = CGRect(x: 0, y: 25, width: 1512, height: 957)
    private let apps = FakeAppControl()
    private let access = FakeWindowAccess()
    private let watcher = FakeAppWatcher()
    private let screens = FakeScreens()
    private let scheduler = FakeScheduler()
    private let kitty = Self.app(1, "net.kovidgoyal.kitty", "kitty")
    private let finder = Self.app(2, "com.apple.finder", "Finder")

    /// A running ordinary app.
    private static func app(_ pid: Int32, _ bundleID: String, _ name: String, isRegular: Bool = true) -> RunningApp {
        RunningApp(pid: pid, bundleID: bundleID, name: name, isActive: false, isHidden: false, isRegular: isRegular)
    }

    /// The module, off, on `screen`.
    private func module() -> WindowManagerModule {
        screens.screen = screen
        let system = WindowManagerSystem(
            apps: apps, windows: access, watcher: watcher, screens: screens, scheduler: scheduler)
        return WindowManagerModule(system: system, log: Log(writer: RecordingLogWriter()))
    }

    /// A window of the app with process ID `pid`, which Accessibility reaches.
    private func window(of pid: Int32) -> FakeAppWindow {
        let window = FakeAppWindow()
        let watched = access.apps[pid] ?? FakeWatchedApp()
        watched.current = (watched.current ?? []) + [window]
        access.apps[pid] = watched
        return window
    }

    @Test func offersToOpenApps() {
        #expect(module().hotkeys.opensApps)
        #expect(module().permissions == [.accessibility])
    }

    @Test func startFillsTheScreenWithRunningAppsWindows() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        #expect(module.status == .running)
        #expect(watcher.isStarted)
        #expect(window.frame == visibleArea)
    }

    @Test func appsWithoutADockIconAreLeftAlone() async throws {
        let window = window(of: 3)
        let before = window.frame
        watcher.apps = [Self.app(3, "com.example.menu", "Menu", isRegular: false)]
        try await module().start()
        #expect(window.frame == before)
    }

    @Test func fullFrameFillsTheWholeScreen() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        module.apply(["frame": .string("full")])
        try await module.start()
        #expect(window.frame == CGRect(x: 0, y: 0, width: 1512, height: 982))
    }

    @Test func newSettingsLayTheWindowsOutAgain() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        module.apply(["frame": .string("full")])
        #expect(window.frame == CGRect(x: 0, y: 0, width: 1512, height: 982))
    }

    @Test func launchedAppIsTracked() async throws {
        let module = module()
        try await module.start()
        let window = window(of: kitty.pid)
        watcher.send(.launched(kitty))
        #expect(window.frame == visibleArea)
    }

    @Test func appThatDoesntAnswerYetIsLookedAtAgain() async throws {
        let module = module()
        try await module.start()
        watcher.send(.launched(kitty))
        let window = window(of: kitty.pid)
        #expect(window.frame != visibleArea)
        scheduler.runPending()
        #expect(window.frame == visibleArea)
    }

    @Test func quitAppIsNoLongerWatched() async throws {
        _ = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        watcher.send(.terminated(kitty.pid))
        #expect(access.apps[kitty.pid]?.isStopped == true)
    }

    @Test func activatedAppHidesTheOthers() async throws {
        apps.running = [kitty.bundleID ?? "": kitty, finder.bundleID ?? "": finder]
        let module = module()
        try await module.start()
        watcher.send(.activated(kitty))
        #expect(apps.calls == ["hide Finder"])
    }

    @Test func hideOthersOffHidesNothing() async throws {
        apps.running = [kitty.bundleID ?? "": kitty, finder.bundleID ?? "": finder]
        let module = module()
        module.apply(["hide_others": .boolean(false)])
        try await module.start()
        watcher.send(.activated(kitty))
        #expect(apps.calls.isEmpty)
    }

    @Test func appShortcutRunsTheApp() async throws {
        let module = module()
        try await module.start()
        module.perform(.app("com.apple.finder"))
        await module.raising?.value
        #expect(apps.calls == ["open com.apple.finder"])
    }

    @Test func moduleActionsAreNotItsOwn() async throws {
        let module = module()
        try await module.start()
        module.perform(.module("launcher"))
        #expect(module.raising == nil)
    }

    @Test func stopLeavesEveryApp() async throws {
        _ = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        await module.stop()
        #expect(module.status == .off)
        #expect(!watcher.isStarted)
        #expect(access.apps[kitty.pid]?.isStopped == true)
        scheduler.runPending()
        watcher.send(.launched(finder))
        #expect(access.apps[finder.pid] == nil)
    }
}
