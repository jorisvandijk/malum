import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SelfSigningTests {
    let paths = Paths(home: "/Users/test")
    let plist = "/Users/test/Applications/Malum.app/Contents/Info.plist"
    let fingerprint = SigningCertificateTests.fingerprint

    /// The installed app, with the key file the first start made.
    private func installed() -> FakeFileSystem {
        let files = FakeFileSystem(texts: [plist: "app"])
        SigningCertificateTests.keep(in: files)
        return files
    }

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
        let output = fingerprint
        let runner = FakeRunner { _ in CommandResult(status: 0, output: output) }
        let outcome = await signing(runner, files: installed()).check(executable: paths.installedExecutable)
        #expect(outcome == .signed)
        #expect(runner.commands.map { $0.arguments.first } == ["x509", "--verify"])
    }

    @Test func unsignedAppIsSignedWithTheCertificate() async {
        let output = fingerprint
        let bundle = paths.installedBundle
        let runner = FakeRunner { command in
            let unsigned = command.arguments.first == "--verify" && command.arguments.last == bundle
            return unsigned ? CommandResult(status: 1) : CommandResult(status: 0, output: output)
        }
        let outcome = await signing(runner, files: installed()).check(executable: paths.installedExecutable)
        #expect(outcome == .resigned)
        #expect(runner.commands.map { $0.arguments.first } == ["x509", "--verify", "sign", "--verify"])
        #expect(runner.commands[2].executable == paths.signingTool)
    }

    @Test func missingCertificateIsMadeFirst() async {
        let runner = FakeRunner { _ in CommandResult(status: 0) }
        let outcome = await signing(runner, files: FakeFileSystem(texts: [plist: "app"]))
            .check(executable: paths.installedExecutable)
        guard case .failed(.files) = outcome else {
            Issue.record("expected the missing certificate files, got \(outcome)")
            return
        }
        #expect(runner.commands.map { $0.arguments.first } == ["req"])
    }

    @Test func loadedAgentIsRestarted() async throws {
        let runner = FakeRunner()
        try await signing(runner, files: FakeFileSystem()).restart(userID: 501)
        #expect(runner.commands.last == Launchctl.restart("gui/501/\(Project.bundleID)"))
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
