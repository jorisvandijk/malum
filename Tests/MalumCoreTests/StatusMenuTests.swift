import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct StatusMenuTests {
    private let path = "/dots/malum.toml"

    private func report(_ problems: [ConfigProblem], loaded: String? = "/dots/malum.toml") -> ConfigReport {
        ConfigReport(loaded: loaded, changed: [], kept: [], problems: problems)
    }

    @Test func calmMenuListsNoModulesAndNoProblems() {
        let menu = StatusMenu(modules: [], report: report([]), configPath: path, configExists: true)
        #expect(
            menu.items == [
                .text("Malum dev"), .separator,
                .text("no modules yet"), .separator,
                .text("malum.toml has no problems"), .action("Open malum.toml", .openFile(path)), .separator,
                .action("Reload malum.toml", .reload), .action("Quit Malum", .quit),
            ])
        #expect(!menu.needsAttention)
    }

    @Test func configProblemsAreListedWithTheirTags() {
        let problems = [ConfigProblem(.warn, line: 1, "unknown module samba")]
        let menu = StatusMenu(modules: [], report: report(problems), configPath: path, configExists: true)
        #expect(menu.items.contains(.text("[warn] malum.toml line 1: unknown module samba")))
        #expect(!menu.items.contains(.text("malum.toml has no problems")))
        #expect(menu.needsAttention)
    }

    @Test func missingFileOffersTheDotsFolder() {
        let problems = [ConfigProblem(.error, "couldn't load \(private: path): it doesn't exist")]
        let menu = StatusMenu(
            modules: [], report: report(problems, loaded: nil), configPath: path, configExists: false)
        #expect(menu.items.contains(.action("Show dots folder", .showFolder("/dots"))))
        #expect(!menu.items.contains(.action("Open malum.toml", .openFile(path))))
    }

    @Test func noDotsOffersNoWayToTheFile() {
        let problems = [ConfigProblem(.error, "couldn't load malum.toml: no dots folder yet, run malum init")]
        let menu = StatusMenu(modules: [], report: report(problems, loaded: nil), configPath: nil, configExists: false)
        #expect(
            !menu.items.contains {
                if case .action(_, .openFile) = $0 { return true }
                if case .action(_, .showFolder) = $0 { return true }
                return false
            })
    }

    @Test func unparsableFileStillOffersToOpenIt() {
        let problems = [ConfigProblem(.error, line: 3, column: 7, "cannot redefine existing integer 'gap'")]
        let menu = StatusMenu(modules: [], report: report(problems, loaded: nil), configPath: path, configExists: true)
        #expect(menu.items.contains(.action("Open malum.toml", .openFile(path))))
    }

    @Test func modulesShowTheirStatusInOrder() {
        let modules: [(id: String, status: ModuleStatus)] = [("launcher", .running), ("samba", .off)]
        let menu = StatusMenu(modules: modules, report: report([]), configPath: path, configExists: true)
        #expect(Array(menu.items[2...3]) == [.text("launcher: running"), .text("samba: off")])
        #expect(!menu.needsAttention)
    }

    @Test func missingPermissionsEachGetASettingsItem() {
        let modules: [(id: String, status: ModuleStatus)] = [
            ("keyboard", .needsPermission([.inputMonitoring, .accessibility]))
        ]
        let menu = StatusMenu(modules: modules, report: report([]), configPath: path, configExists: true)
        #expect(
            Array(menu.items[2...4]) == [
                .text("keyboard: needs Accessibility, Input Monitoring"),
                .action("Open Accessibility settings", .openSettings(.accessibility)),
                .action("Open Input Monitoring settings", .openSettings(.inputMonitoring)),
            ])
        #expect(menu.needsAttention)
    }

    @Test func failedOrDegradedModuleNeedsAttention() {
        for status in [ModuleStatus.failed(reason: "boom"), .degraded(reason: "bad table")] {
            let menu = StatusMenu(
                modules: [(id: "launcher", status: status)], report: report([]), configPath: path, configExists: true)
            #expect(menu.needsAttention)
        }
    }

    @Test func noReportYetShowsNoProblems() {
        let menu = StatusMenu(modules: [], report: nil, configPath: nil, configExists: false)
        #expect(menu.items.contains(.text("malum.toml has no problems")))
        #expect(!menu.needsAttention)
    }
}
