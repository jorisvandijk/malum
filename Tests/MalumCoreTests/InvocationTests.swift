import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct InvocationTests {
    @Test func noArgumentsShowsHelp() {
        #expect(Invocation(arguments: []) == .help)
    }

    @Test(arguments: ["--version", "-v"])
    func versionFlagShowsVersion(flag: String) {
        #expect(Invocation(arguments: [flag]) == .version)
    }

    @Test(arguments: ["--help", "-h"])
    func helpFlagShowsHelp(flag: String) {
        #expect(Invocation(arguments: [flag]) == .help)
    }

    @Test func unknownArgumentIsReported() {
        #expect(Invocation(arguments: ["frobnicate"]) == .unknown("frobnicate"))
    }

    @Test func usageNamesTheCommand() {
        #expect(Invocation.usage.hasPrefix("usage: \(Project.command) "))
    }

    @Test func tokenTakesNoToken() {
        #expect(Invocation(arguments: ["token"]) == .token(remove: false))
        #expect(Invocation(arguments: ["token", "ghp_secret"]) == .unknown("ghp_secret"))
    }

    @Test func tokenRemoveDeletesIt() {
        #expect(Invocation(arguments: ["token", "--remove"]) == .token(remove: true))
        #expect(Invocation(arguments: ["token", "--remove", "extra"]) == .unknown("extra"))
    }

    @Test func initTakesThePathToDots() {
        #expect(Invocation(arguments: ["init", "~/git/dots"]) == .initialize(dots: "~/git/dots"))
    }

    @Test func initWithoutPathIsIncomplete() {
        #expect(Invocation(arguments: ["init"]) == .incomplete(command: "init", needs: "the path to dots"))
    }

    @Test func initWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["init", "~/git/dots", "extra"]) == .unknown("extra"))
    }

    @Test func reloadAsksTheApp() {
        #expect(Invocation(arguments: ["reload"]) == .reload)
    }

    @Test func reloadWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["reload", "now"]) == .unknown("now"))
    }

    @Test func safeTurnsOnSafeMode() {
        #expect(Invocation(arguments: ["safe"]) == .safe)
    }

    @Test func safeWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["safe", "now"]) == .unknown("now"))
    }

    @Test func disableTakesAModule() {
        #expect(Invocation(arguments: ["disable", "launcher"]) == .disable(module: "launcher"))
    }

    @Test func disableWithoutModuleIsIncomplete() {
        #expect(Invocation(arguments: ["disable"]) == .incomplete(command: "disable", needs: "a module"))
    }

    @Test func disableWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["disable", "launcher", "samba"]) == .unknown("samba"))
    }

    @Test func permissionsChecksTheTerminal() {
        #expect(Invocation(arguments: ["permissions"]) == .permissions)
    }

    @Test func runMakesTheMacMatchDots() {
        #expect(Invocation(arguments: ["run"]) == .run(force: false))
    }

    @Test func runWithForceInstallsAnOlderRelease() {
        #expect(Invocation(arguments: ["run", "--force"]) == .run(force: true))
    }

    @Test func runWithForceAndExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["run", "--force", "extra"]) == .unknown("extra"))
    }

    @Test func rollbackPutsThePreviousVersionBack() {
        #expect(Invocation(arguments: ["rollback"]) == .rollback)
    }

    @Test func runWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["run", "extra"]) == .unknown("extra"))
    }

    @Test func statusShowsWhatMalumManages() {
        #expect(Invocation(arguments: ["status"]) == .status)
    }

    @Test func statusWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["status", "extra"]) == .unknown("extra"))
    }

    @Test func permissionsWithExtraArgumentIsReported() {
        #expect(Invocation(arguments: ["permissions", "extra"]) == .unknown("extra"))
    }
}
