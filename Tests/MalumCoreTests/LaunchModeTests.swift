import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LaunchModeTests {
    @Test func launchAgentRunsTheApp() {
        #expect(LaunchMode(environment: ["XPC_SERVICE_NAME": Project.bundleID]) == .app)
    }

    @Test func openingTheAppRunsTheApp() {
        let service = "application.\(Project.bundleID).123456.123457"
        #expect(LaunchMode(environment: ["XPC_SERVICE_NAME": service]) == .app)
    }

    @Test func terminalRunsTheCommand() {
        #expect(LaunchMode(environment: ["XPC_SERVICE_NAME": "0"]) == .command)
    }

    @Test func terminalAppRunsTheCommand() {
        let service = "application.net.kovidgoyal.kitty.123456.123457"
        #expect(LaunchMode(environment: ["XPC_SERVICE_NAME": service]) == .command)
    }

    @Test func appWithLongerBundleIDRunsTheCommand() {
        let service = "application.\(Project.bundleID)helper.123456.123457"
        #expect(LaunchMode(environment: ["XPC_SERVICE_NAME": service]) == .command)
    }

    @Test func noServiceNameRunsTheCommand() {
        #expect(LaunchMode(environment: [:]) == .command)
    }

    @Test func onlyTheAgentsServiceIsTheLoginAgent() {
        #expect(LaunchMode.isLoginAgent(environment: ["XPC_SERVICE_NAME": Project.bundleID]))
        #expect(!LaunchMode.isLoginAgent(environment: ["XPC_SERVICE_NAME": "application.\(Project.bundleID).1.2"]))
        #expect(!LaunchMode.isLoginAgent(environment: [:]))
    }
}
