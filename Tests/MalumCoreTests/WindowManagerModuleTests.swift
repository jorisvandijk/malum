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
    private let picker = FakeWindowPicker()
    private let panel = FakeInspectorPanel()
    private let clipboard = FakeClipboard()
    private let routes = ModuleRoutes()
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
            apps: apps, windows: access, watcher: watcher, screens: screens, scheduler: scheduler,
            inspector: WindowInspectorSystem(picker: picker, panel: panel, clipboard: clipboard))
        return WindowManagerModule(system: system, routes: routes, log: Log(writer: RecordingLogWriter()))
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

    @Test func swallowsHideAndMinimiseKeys() throws {
        let keys = module().hotkeys.fixedKeys
        let hide = Hotkey(modifiers: [.cmd], key: try #require(Key.named("h")))
        let minimiseAll = Hotkey(modifiers: [.cmd, .option], key: try #require(Key.named("m")))
        #expect(keys.count == 3)
        #expect(keys[hide] != nil)
        #expect(keys[minimiseAll] != nil)
    }

    @Test func blockHideMinimizeOffSwallowsNothing() {
        let module = module()
        module.apply(["block_hide_minimize": .boolean(false)])
        #expect(module.hotkeys.fixedKeys.isEmpty)
        #expect(module.hotkeys.opensApps)
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

    @Test func changedScreenLaysTheWindowsOutAgainOnceSettled() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        screens.screen = ScreenRects(
            full: CGRect(x: 0, y: 0, width: 2560, height: 1440), visible: CGRect(x: 0, y: 0, width: 2560, height: 1415))
        watcher.send(.screensChanged)
        watcher.send(.screensChanged)
        #expect(window.frame == visibleArea)
        #expect(scheduler.pending.count == 1)
        scheduler.runPending()
        #expect(window.frame == CGRect(x: 0, y: 25, width: 2560, height: 1415))
    }

    @Test func resumeLaysTheWindowsOutAgain() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        window.frame = CGRect(x: 40, y: 40, width: 500, height: 400)
        await module.resume()
        #expect(window.frame == visibleArea)
    }

    @Test func noScreenLeavesTheWindowsWhereTheyAre() async throws {
        let window = window(of: kitty.pid)
        watcher.apps = [kitty]
        let module = module()
        try await module.start()
        let moved = CGRect(x: 40, y: 40, width: 500, height: 400)
        window.frame = moved
        screens.screen = nil
        watcher.send(.screensChanged)
        scheduler.runPending()
        #expect(window.frame == moved)
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

    /// The value of the inspector's line `label`, or nil when nothing was shown.
    private func shown(_ label: String) -> String? {
        panel.shown?.first { $0.label == label }?.value
    }

    /// Inspects a window of the running module and waits for it.
    private func inspect(_ module: WindowManagerModule) async {
        module.perform(.module(WindowManagerModule.inspectAction))
        await module.raising?.value
    }

    @Test func offersTheInspectAndToggleFloatActions() {
        #expect(
            module().hotkeys.actions == [WindowManagerModule.inspectAction, WindowManagerModule.toggleFloatAction])
    }

    @Test func inspectShowsTheClickedWindow() async throws {
        watcher.apps = [kitty]
        let window = window(of: kitty.pid)
        let module = module()
        try await module.start()
        routes.appKeys = [kitty.bundleID ?? "": [Hotkey(modifiers: Set(Modifier.allCases), key: Key.tab)]]
        access.pointerLocation = CGPoint(x: 40, y: 50)
        access.pointed = PointedWindow(pid: kitty.pid, window: window)
        await inspect(module)
        #expect(access.lookedAt == [CGPoint(x: 40, y: 50)])
        #expect(shown("app") == "kitty")
        #expect(shown("bundle id") == "net.kovidgoyal.kitty")
        #expect(shown("title") == "Main")
        #expect(shown("role") == "AXWindow / AXStandardWindow")
        #expect(shown("frame") == "1512x957 at 0,25")
        #expect(shown("workspace") == "hyper+tab")
        #expect(shown("window manager") == "managed")
    }

    @Test func inspectSaysWhyAWindowFloats() async throws {
        watcher.apps = [kitty]
        let window = window(of: kitty.pid)
        window.facts.subrole = "AXDialog"
        let module = module()
        try await module.start()
        access.pointed = PointedWindow(pid: kitty.pid, window: window)
        await inspect(module)
        #expect(shown("window manager") == "floats: it's a AXDialog")
        #expect(shown("workspace") == "none")
    }

    @Test func inspectSaysAnUntrackedAppIsLeftAlone() async throws {
        let menuBarApp = Self.app(3, "com.example.menu", "Menu", isRegular: false)
        watcher.apps = [menuBarApp]
        let module = module()
        try await module.start()
        access.pointed = PointedWindow(pid: menuBarApp.pid, window: FakeAppWindow())
        await inspect(module)
        #expect(shown("window manager")?.hasPrefix("left alone") == true)
    }

    @Test func cancelledInspectShowsNothing() async throws {
        picker.clicks = false
        let module = module()
        try await module.start()
        await inspect(module)
        #expect(picker.picks == 1)
        #expect(access.lookedAt.isEmpty)
        #expect(panel.shown == nil)
    }

    @Test func clickOnNoWindowShowsNothing() async throws {
        let module = module()
        try await module.start()
        await inspect(module)
        #expect(access.lookedAt.count == 1)
        #expect(panel.shown == nil)
    }

    @Test func copyPutsTheReportOnTheClipboard() async throws {
        watcher.apps = [kitty]
        let window = window(of: kitty.pid)
        window.facts.title = nil
        let module = module()
        try await module.start()
        access.pointed = PointedWindow(pid: kitty.pid, window: window)
        await inspect(module)
        panel.clickCopy()
        let text = try #require(clipboard.put.first?.0.text)
        #expect(text.hasPrefix("app: kitty\nbundle id: net.kovidgoyal.kitty\ntitle: none\n"))
    }

    @Test func toggleFloatFloatsTheFocusedWindowOfTheAppInFront() async throws {
        let active = RunningApp(
            pid: kitty.pid, bundleID: kitty.bundleID, name: kitty.name, isActive: true, isHidden: false,
            isRegular: true)
        apps.running = [kitty.bundleID ?? "": active]
        watcher.apps = [kitty]
        let window = window(of: kitty.pid)
        access.apps[kitty.pid]?.focused = window
        let module = module()
        try await module.start()
        module.perform(.module(WindowManagerModule.toggleFloatAction))
        #expect(window.frame == WindowLayout.floated(in: visibleArea))
    }
}
