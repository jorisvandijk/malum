import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct RunRaiseTests {
    private let apps = FakeAppControl()
    private let writer = RecordingLogWriter()
    private let scheduler = FakeScheduler()
    private let finder = "com.apple.finder"

    /// Run or raise, logging to `writer`, kept for the whole test so its later looks still run.
    private let raiser: RunRaise

    init() {
        raiser = RunRaise(apps: apps, scheduler: scheduler, log: Log(writer: writer))
    }

    /// A running app.
    private func app(
        _ pid: Int32, _ name: String, active: Bool = false, hidden: Bool = false, regular: Bool = true
    ) -> RunningApp {
        RunningApp(
            pid: pid, bundleID: "test.\(name)", name: name, isActive: active, isHidden: hidden, isRegular: regular)
    }

    @Test func appThatDoesNotRunLaunches() {
        #expect(RunRaise.steps(for: nil, windows: .unknown) == [.launch])
    }

    @Test func frontmostAppWithWindowsIsLeftAlone() {
        #expect(RunRaise.steps(for: app(1, "Finder", active: true), windows: .some).isEmpty)
        #expect(RunRaise.steps(for: app(1, "Finder", active: true), windows: .unknown).isEmpty)
    }

    @Test func appBehindAnotherIsActivated() {
        #expect(RunRaise.steps(for: app(1, "Finder"), windows: .some) == [.activate])
    }

    @Test func hiddenAppIsShownThenActivated() {
        #expect(RunRaise.steps(for: app(1, "Finder", hidden: true), windows: .some) == [.unhide, .activate])
    }

    @Test func appWithoutWindowsIsReopened() {
        #expect(
            RunRaise.steps(for: app(1, "Finder", hidden: true), windows: .noWindows) == [.unhide, .activate, .reopen])
        #expect(RunRaise.steps(for: app(1, "Finder", active: true), windows: .noWindows) == [.reopen])
    }

    @Test func appWithOnlyMinimisedWindowsGetsOneBack() {
        #expect(RunRaise.steps(for: app(1, "Finder"), windows: .onlyMinimized) == [.activate, .unminimize])
    }

    @Test func raiseOpensAnAppThatDoesNotRun() async {
        await raiser.raise(finder)
        #expect(apps.calls == ["open \(finder)"])
    }

    @Test func appStartedWithoutAWindowIsAskedForOne() async {
        await raiser.raise(finder)
        apps.running[finder] = app(1, "Finder")
        apps.windows[1] = .noWindows
        scheduler.runPending()
        await raiser.reopening?.value
        #expect(apps.calls == ["open \(finder)", "open \(finder)"])
    }

    @Test func appStartedWithAWindowIsLeftAlone() async {
        await raiser.raise(finder)
        apps.running[finder] = app(1, "Finder")
        apps.windows[1] = .some
        scheduler.runPending()
        #expect(apps.calls == ["open \(finder)"])
        #expect(scheduler.pending.isEmpty)
    }

    @Test func startedAppThatDoesNotAnswerIsLookedAtAgain() async {
        await raiser.raise(finder)
        apps.running[finder] = app(1, "Finder")
        scheduler.runPending()
        #expect(scheduler.pending.count == 1)
    }

    @Test func appThatFailedToStartIsNotLookedAt() async {
        await raiser.raise(finder)
        scheduler.runPending()
        #expect(apps.calls == ["open \(finder)"])
        #expect(scheduler.pending.isEmpty)
    }

    @Test func runningAppIsNotLookedAtAgain() async {
        apps.running[finder] = app(1, "Finder")
        apps.windows[1] = .noWindows
        await raiser.raise(finder)
        #expect(scheduler.pending.isEmpty)
    }

    @Test func raiseTakesEveryStep() async {
        let hidden = app(1, "Finder", hidden: true)
        apps.running[finder] = hidden
        apps.windows[1] = .noWindows
        await raiser.raise(finder)
        #expect(apps.calls == ["unhide Finder", "activate Finder", "open \(finder)"])
    }

    @Test func failedOpenIsLogged() async {
        apps.openError = .notInstalled(finder)
        await raiser.raise(finder)
        #expect(writer.entries.map(\.text) == [Message.failed(WindowManagerError.notInstalled(finder)).text])
    }

    @Test func activeAppHidesTheOthers() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder"), "Mail": app(3, "Mail")]
        raiser.hideOthers(except: kitty, config: WindowManagerConfig())
        #expect(apps.calls == ["hide Finder", "hide Mail"])
        #expect(writer.entries.isEmpty)
    }

    @Test func appsThatStayInViewAreLogged() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder")]
        apps.refusesToHide = [2]
        raiser.hideOthers(except: kitty, config: WindowManagerConfig())
        #expect(writer.entries.map(\.text) == [Message.couldntHide(["Finder"]).text])
    }

    @Test func appsWithoutADockIconOrThatFloatHideNothing() {
        let kitty = app(1, "kitty", active: true)
        #expect(!RunRaise.hidesOthers(for: app(1, "Menu", regular: false), config: WindowManagerConfig()))
        let floats = WindowManagerConfig(floats: [FloatRule(app: "test.kitty", title: nil)])
        #expect(!RunRaise.hidesOthers(for: kitty, config: floats))
        let titled = WindowManagerConfig(floats: [FloatRule(app: "test.kitty", title: "^About$")])
        #expect(RunRaise.hidesOthers(for: kitty, config: titled))
    }
}
