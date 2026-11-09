import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct RunRaiseTests {
    private let apps = FakeAppControl()
    private let scheduler = FakeScheduler()
    private let writer = RecordingLogWriter()
    private let finder = "com.apple.finder"

    /// Run or raise, logging to `writer`.
    private func runRaise() -> RunRaise {
        RunRaise(apps: apps, scheduler: scheduler, log: Log(writer: writer))
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
        await runRaise().raise(finder)
        #expect(apps.calls == ["open \(finder)"])
    }

    @Test func raiseTakesEveryStep() async {
        let hidden = app(1, "Finder", hidden: true)
        apps.running[finder] = hidden
        apps.windows[1] = .noWindows
        await runRaise().raise(finder)
        #expect(apps.calls == ["unhide Finder", "activate Finder", "open \(finder)"])
    }

    @Test func failedOpenIsLogged() async {
        apps.openError = .notInstalled(finder)
        await runRaise().raise(finder)
        #expect(writer.entries.map(\.text) == [Message.failed(WindowManagerError.notInstalled(finder)).text])
    }

    @Test func activeAppHidesTheOthers() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder"), "Mail": app(3, "Mail")]
        runRaise().hideOthers(except: kitty, config: WindowManagerConfig())
        #expect(apps.calls == ["hide Finder", "hide Mail"])
        #expect(writer.entries.isEmpty)
    }

    @Test func appThatStaysInViewIsHiddenAgainALittleLater() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder")]
        apps.refusesToHide = [2]
        let runRaise = runRaise()
        runRaise.hideOthers(except: kitty, config: WindowManagerConfig())
        apps.refusesToHide = []
        scheduler.runPending()
        #expect(apps.calls == ["hide Finder", "hide Finder"])
        #expect(writer.entries.isEmpty)
    }

    @Test func appsThatStayInViewAreLoggedOnceEveryTryFailed() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder")]
        apps.refusesToHide = [2]
        let runRaise = runRaise()
        runRaise.hideOthers(except: kitty, config: WindowManagerConfig())
        while !scheduler.pending.isEmpty {
            scheduler.runPending()
        }
        #expect(apps.calls == Array(repeating: "hide Finder", count: 4))
        #expect(writer.entries.map(\.text) == [Message.couldntHide(["Finder"]).text])
    }

    @Test func hidingStopsOnceAnotherAppIsInFront() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder")]
        apps.refusesToHide = [2]
        let runRaise = runRaise()
        runRaise.hideOthers(except: kitty, config: WindowManagerConfig())
        apps.running["kitty"] = app(1, "kitty")
        scheduler.runPending()
        #expect(apps.calls == ["hide Finder"])
        #expect(scheduler.pending.isEmpty)
        #expect(writer.entries.isEmpty)
    }

    @Test func switchThatDidNotTakeIsTriedAgain() async {
        apps.running[finder] = app(1, "Finder")
        apps.windows[1] = .some
        let runRaise = runRaise()
        await runRaise.raise(finder)
        scheduler.runPending()
        apps.running[finder] = app(1, "Finder", active: true)
        scheduler.runPending()
        #expect(apps.calls == ["activate Finder", "activate Finder"])
        #expect(scheduler.pending.isEmpty)
    }

    @Test func switchThatNeverTakesIsLogged() async {
        apps.running[finder] = app(1, "Finder", hidden: true)
        apps.windows[1] = .some
        let runRaise = runRaise()
        await runRaise.raise(finder)
        while !scheduler.pending.isEmpty {
            scheduler.runPending()
        }
        let again = Array(repeating: ["unhide Finder", "activate Finder"], count: 4).flatMap(\.self)
        #expect(apps.calls == again)
        #expect(writer.entries.map(\.text) == [Message.couldntRaise("Finder").text])
    }

    @Test func olderSwitchStopsForANewerShortcut() async {
        let mail = "test.Mail"
        apps.running = [finder: app(1, "Finder"), mail: app(2, "Mail")]
        apps.windows = [1: .some, 2: .some]
        let runRaise = runRaise()
        await runRaise.raise(finder)
        await runRaise.raise(mail)
        scheduler.runPending()
        #expect(apps.calls == ["activate Finder", "activate Mail", "activate Mail"])
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
