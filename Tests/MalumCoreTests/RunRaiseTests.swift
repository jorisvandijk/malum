import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct RunRaiseTests {
    private let apps = FakeAppControl()
    private let writer = RecordingLogWriter()
    private let finder = "com.apple.finder"

    /// Run or raise, logging to `writer`.
    private func runRaise() -> RunRaise {
        RunRaise(apps: apps, log: Log(writer: writer))
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

    @Test func appsThatStayInViewAreLogged() {
        let kitty = app(1, "kitty", active: true)
        apps.running = ["kitty": kitty, "Finder": app(2, "Finder")]
        apps.refusesToHide = [2]
        runRaise().hideOthers(except: kitty, config: WindowManagerConfig())
        #expect(writer.entries.map(\.text) == [Message.couldntHide(["Finder"]).text])
    }

    @Test func nothingIsHiddenWhenTheSettingsSayNo() {
        let kitty = app(1, "kitty", active: true)
        #expect(!RunRaise.hidesOthers(for: kitty, config: WindowManagerConfig(hidesOthers: false)))
        #expect(!RunRaise.hidesOthers(for: app(1, "Menu", regular: false), config: WindowManagerConfig()))
        let floats = WindowManagerConfig(floats: [FloatRule(app: "test.kitty", title: nil)])
        #expect(!RunRaise.hidesOthers(for: kitty, config: floats))
        let titled = WindowManagerConfig(floats: [FloatRule(app: "test.kitty", title: "^About$")])
        #expect(RunRaise.hidesOthers(for: kitty, config: titled))
    }
}
