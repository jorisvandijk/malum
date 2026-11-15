import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct StatusMenuTests {
    private let path = "/dots/malum.toml"
    /// The actions at the bottom while `malum.toml` is there.
    private var actions: [MenuItem] {
        [
            .action("Run", .run), .action("Show log", .showLog), .action("Reload", .reload), .separator,
            .action("About Malum", .about), .action("Quit Malum", .quit),
        ]
    }

    private func report(_ problems: [ConfigProblem], loaded: String? = "/dots/malum.toml") -> ConfigReport {
        ConfigReport(loaded: loaded, changed: [], kept: [], problems: problems)
    }

    private func menu(
        modules: [(id: String, status: ModuleStatus)] = [], problems: [ConfigProblem] = [],
        overrides: Overrides = Overrides(), signingProblem: String? = nil
    ) -> StatusMenu {
        StatusMenu(
            modules: modules, report: report(problems), configPath: path, configExists: true, overrides: overrides,
            signingProblem: signingProblem)
    }

    @Test func calmMenuHoldsOnlyTheActions() {
        let calm = menu(modules: [("launcher", .running), ("samba", .off)])
        #expect(calm.items == actions)
        #expect(!calm.needsAttention)
    }

    @Test func runningWindowManagerOffersTheInspector() {
        let running = menu(modules: [("window_manager", .running)])
        #expect(
            Array(running.items.prefix(3)) == [
                .action("Run", .run), .action("Inspect window", .runAction("inspect_window")),
                .action("Show log", .showLog),
            ])
        let off = menu(modules: [("window_manager", .off)])
        #expect(!off.items.contains(.action("Inspect window", .runAction("inspect_window"))))
    }

    @Test func signingProblemLeadsToTheLog() {
        let signing = menu(signingProblem: "not signed")
        #expect(signing.items == [.action("not signed", .showLog), .separator] + actions)
        #expect(signing.needsAttention)
    }

    @Test func configProblemsOpenTheFile() {
        let problems = [ConfigProblem(.warn, line: 1, "unknown module samba")]
        let listed = menu(problems: problems)
        #expect(listed.items.first == .action("[warn] malum.toml line 1: unknown module samba", .openFile(path)))
        #expect(listed.needsAttention)
    }

    @Test func missingFileShowsTheDotsFolder() {
        let problems = [ConfigProblem(.error, "couldn't load \(private: path): it doesn't exist")]
        let missing = StatusMenu(
            modules: [], report: report(problems, loaded: nil), configPath: path, configExists: false)
        #expect(
            missing.items.first
                == .action("[error] couldn't load /dots/malum.toml: it doesn't exist", .showFolder("/dots")))
    }

    @Test func noDotsLeadsToTheLog() {
        let problems = [ConfigProblem(.error, "couldn't load malum.toml: no dots folder yet, run malum init")]
        let noDots = StatusMenu(
            modules: [], report: report(problems, loaded: nil), configPath: nil, configExists: false)
        #expect(
            noDots.items.first
                == .action("[error] couldn't load malum.toml: no dots folder yet, run malum init", .showLog))
        #expect(!noDots.items.contains { if case .action(_, .openFile) = $0 { true } else { false } })
    }

    @Test func missingPermissionsEachOpenTheirSettings() {
        let waiting = menu(modules: [("keyboard", .needsPermission([.inputMonitoring, .accessibility]))])
        #expect(
            Array(waiting.items.prefix(2)) == [
                .action("keyboard: open Accessibility settings", .openSettings(.accessibility)),
                .action("keyboard: open Input Monitoring settings", .openSettings(.inputMonitoring)),
            ])
        #expect(waiting.needsAttention)
    }

    @Test func failedOrDegradedModuleLeadsToTheLog() {
        for status in [ModuleStatus.failed(reason: "boom"), .degraded(reason: "bad table")] {
            let broken = menu(modules: [(id: "launcher", status: status)])
            #expect(broken.items.first == .action("launcher: \(status)", .showLog))
            #expect(broken.needsAttention)
        }
    }

    @Test func noReportYetIsCalm() {
        let early = StatusMenu(modules: [], report: nil, configPath: nil, configExists: false)
        #expect(early.items.first == .action("Run", .run))
        #expect(!early.needsAttention)
    }

    @Test func safeModeOffersTheWayOutWithItsReason() {
        let safe = menu(overrides: Overrides(safeMode: .crashLoop))
        #expect(
            safe.items.first == .action("Leave safe mode (Malum started 3 times within 2 minutes)", .leaveSafeMode))
        #expect(safe.needsAttention)
    }

    @Test func disabledModulesEachGetAnEnableItem() {
        let disabled = menu(overrides: Overrides(disabled: ["samba", "launcher"]))
        #expect(
            Array(disabled.items.prefix(3)) == [
                .action("Enable launcher", .enable("launcher")), .action("Enable samba", .enable("samba")), .separator,
            ])
        #expect(disabled.needsAttention)
    }
}
