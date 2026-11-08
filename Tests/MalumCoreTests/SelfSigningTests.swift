import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SelfSigningTests {
    let paths = Paths(home: "/Users/test")
    let plist = "/Users/test/Applications/Malum.app/Contents/Info.plist"
    let listed = "  1) \(SigningCertificateTests.hash) \"Malum code signing\"\n"

    private func signing(_ runner: FakeRunner, files: FakeFileSystem) -> SelfSigning {
        let certificate = SigningCertificate(runner: runner, files: files, paths: paths, temporaryDirectory: "/tmp")
        return SelfSigning(runner: runner, files: files, paths: paths, certificate: certificate)
    }

    @Test func buildFolderIsNotInstalled() async {
        let runner = FakeRunner()
        let built = "/Users/test/Git/malum/build/Malum.app/Contents/MacOS/Malum"
        #expect(await signing(runner, files: FakeFileSystem()).check(executable: built) == .notInstalled)
        #expect(await signing(runner, files: FakeFileSystem()).check(executable: nil) == .notInstalled)
        #expect(runner.commands.isEmpty)
    }

    @Test func signedAppIsLeftAlone() async {
        let output = listed
        let runner = FakeRunner { _ in CommandResult(status: 0, output: output) }
        let outcome = await signing(runner, files: FakeFileSystem(texts: [plist: "app"]))
            .check(executable: paths.installedExecutable)
        #expect(outcome == .signed)
        #expect(runner.commands.map { $0.arguments.first } == ["find-identity", "--verify"])
    }

    @Test func unsignedAppIsSignedWithTheCertificate() async {
        let output = listed
        let bundle = paths.installedBundle
        let runner = FakeRunner { command in
            let unsigned = command.arguments.first == "--verify" && command.arguments.last == bundle
            return unsigned ? CommandResult(status: 1) : CommandResult(status: 0, output: output)
        }
        let outcome = await signing(runner, files: FakeFileSystem(texts: [plist: "app"]))
            .check(executable: paths.installedExecutable)
        #expect(outcome == .resigned)
        #expect(runner.commands.map { $0.arguments.first } == ["find-identity", "--verify", "--force", "--verify"])
    }

    @Test func missingCertificateIsMadeFirst() async {
        let runner = FakeRunner { _ in CommandResult(status: 0) }
        let outcome = await signing(runner, files: FakeFileSystem(texts: [plist: "app"]))
            .check(executable: paths.installedExecutable)
        #expect(outcome == .failed(.unlisted))
        #expect(
            runner.commands.map { $0.arguments.first } == ["find-identity", "req", "pkcs12", "import", "find-identity"])
    }

    @Test func loadedAgentIsRestarted() async throws {
        let runner = FakeRunner()
        try await signing(runner, files: FakeFileSystem()).restart(userID: 501)
        #expect(runner.commands.last == Launchctl.restart("gui/501/com.jorisvandijk.malum"))
    }

    @Test func unloadedAgentIsLoaded() async throws {
        let runner = FakeRunner { command in CommandResult(status: command.arguments.first == "print" ? 113 : 0) }
        try await signing(runner, files: FakeFileSystem()).restart(userID: 501)
        #expect(runner.commands.last == Launchctl.load(paths.loginAgent, into: "gui/501"))
    }

    @Test func failedRestartIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 5, errors: "Bootstrap failed: 5: Input/output error\n") }
        await #expect(throws: SigningError.unrestartable(reason: "Bootstrap failed: 5: Input/output error")) {
            try await signing(runner, files: FakeFileSystem()).restart(userID: 501)
        }
    }
}
