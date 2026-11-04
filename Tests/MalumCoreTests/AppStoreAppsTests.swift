import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppStoreAppsTests {
    private let masInstalled = FakeFileSystem(items: ["/opt/homebrew/bin/mas": .file])
    private let xcode = AppStoreApp("xcode", id: 497_799_835)
    private let amphetamine = AppStoreApp("amphetamine", id: 937_984_704)

    private var state: StateFolder {
        StateFolder(files: masInstalled, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
    }

    /// The App Store apps in the record of what Malum installed.
    private var managed: [String: Int] { (try? InstalledRecord.read(from: state).appStore) ?? [:] }

    /// Records `apps` as managed by Malum.
    private func manage(_ apps: [String: Int]) throws {
        try InstalledRecord.change(in: state) { $0.appStore = apps }
    }

    /// A runner whose `mas list` gives `installed`, whose sudo prompt gives `password`, and whose
    /// installs of `failing` fail.
    private func mas(installed: String = "", password: Int32 = 0, failing: Set<String> = []) -> FakeRunner {
        FakeRunner { command in
            switch command.arguments.first {
            case "list":
                CommandResult(status: 0, output: installed)
            case "-v":
                CommandResult(status: password)
            case _ where command.arguments.last.map(failing.contains) == true:
                CommandResult(status: 1)
            default:
                CommandResult(status: 0)
            }
        }
    }

    private func run(
        _ apps: [AppStoreApp], runner: FakeRunner, files: FakeFileSystem? = nil, canAsk: Bool = true
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let sudo = SudoSession(runner: runner, canAsk: canAsk)
        defer { sudo.end() }
        let files = files ?? masInstalled
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
        let part = AppStoreApps(runner: runner, files: files, sudo: sudo, state: state)
        let succeeded = await part.run(apps) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func nothingListedRunsNothing() async {
        let runner = mas()
        let (succeeded, messages) = await run([], runner: runner, files: FakeFileSystem())
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }

    @Test func missingAppsAreInstalledAfterOnePasswordPrompt() async {
        let runner = mas(installed: "497799835  Xcode  (26.0)\n")
        let (succeeded, messages) = await run([amphetamine, xcode], runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Mas.installed, Sudo.authorize, Mas.install(937_984_704)])
        #expect(
            messages == [
                Message(.info, "App Store app xcode was already installed, Malum manages it now"),
                Message(.info, "asking for your password to install App Store apps"),
                Message(.info, "installing App Store app amphetamine (937984704)"),
                Message(.info, "installed App Store app amphetamine"),
            ])
    }

    @Test func installedAppsAreTakenOverWithoutAPassword() async {
        let runner = mas(installed: "497799835  Xcode  (26.0)\n")
        let (succeeded, messages) = await run([xcode], runner: runner)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "App Store app xcode was already installed, Malum manages it now"),
                Message(.info, "every listed App Store app is installed"),
            ])
        #expect(runner.commands == [Mas.installed])
        #expect(managed == ["xcode": 497_799_835])
        let (_, again) = await run([xcode], runner: runner)
        #expect(again == [Message(.info, "every listed App Store app is installed")])
    }

    @Test func installsAreRecorded() async {
        _ = await run([amphetamine], runner: mas())
        #expect(managed == ["amphetamine": 937_984_704])
    }

    @Test func unlistedAppsMalumManagesAreUninstalledAfterOnePrompt() async throws {
        try manage(["amphetamine": 937_984_704, "pages": 409_201_541])
        let runner = mas(installed: "937984704  Amphetamine  (5.3)\n")
        let (succeeded, messages) = await run([xcode], runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [Mas.installed, Sudo.authorize, Mas.install(497_799_835), Mas.uninstall(937_984_704)])
        #expect(
            messages == [
                Message(.info, "App Store app pages was already uninstalled"),
                Message(.info, "asking for your password to install and uninstall App Store apps"),
                Message(.info, "installing App Store app xcode (497799835)"),
                Message(.info, "installed App Store app xcode"),
                Message(.info, "uninstalling App Store app amphetamine (937984704)"),
                Message(.info, "uninstalled App Store app amphetamine"),
            ])
        #expect(managed == ["xcode": 497_799_835])
    }

    @Test func failedUninstallStaysManaged() async throws {
        try manage(["amphetamine": 937_984_704])
        let runner = mas(installed: "937984704  Amphetamine  (5.3)\n", failing: ["937984704"])
        let (succeeded, messages) = await run([], runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't uninstall App Store app amphetamine: exited with 1"))
        #expect(managed == ["amphetamine": 937_984_704])
    }

    @Test func withoutMasNothingRuns() async {
        let runner = mas()
        let (succeeded, messages) = await run([xcode], runner: runner, files: FakeFileSystem())
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    """
                    couldn't install App Store apps: mas isn't installed at /opt/homebrew/bin/mas, \
                    add mas = "formula" to [homebrew] in packages.toml
                    """)
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func refusedPasswordInstallsNothing() async {
        let runner = mas(password: 1)
        let (succeeded, messages) = await run([xcode], runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't install App Store apps: sudo wasn't granted"))
        #expect(runner.commands == [Mas.installed, Sudo.authorize])
    }

    @Test func outsideATerminalNothingAsks() async {
        let runner = mas()
        let (succeeded, messages) = await run([xcode], runner: runner, canAsk: false)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't install App Store apps: it needs your password, so run it from a terminal")
            ])
        #expect(runner.commands == [Mas.installed])
    }

    @Test func failedInstallIsReportedAndTheRestGoOn() async {
        let runner = mas(failing: ["937984704"])
        let (succeeded, messages) = await run([amphetamine, xcode], runner: runner)
        #expect(!succeeded)
        #expect(messages.contains(Message(.error, "couldn't install App Store app amphetamine: exited with 1")))
        #expect(messages.last == Message(.info, "installed App Store app xcode"))
    }

    @Test func passwordIsAskedOncePerRun() async {
        let runner = mas()
        let sudo = SudoSession(runner: runner, canAsk: true)
        defer { sudo.end() }
        #expect(await sudo.authorize(for: "do one thing") { _ in })
        #expect(await sudo.authorize(for: "do another") { _ in })
        #expect(runner.commands == [Sudo.authorize])
    }
}
