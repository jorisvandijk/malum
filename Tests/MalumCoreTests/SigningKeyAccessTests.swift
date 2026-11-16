import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SigningKeyAccessTests {
    static let hash = SigningCertificateTests.hash
    let paths = Paths(home: "/Users/test")
    let files = FakeFileSystem()

    private var state: StateFolder { StateFolder(files: files, locks: FakeFileLocks(), paths: paths) }

    /// A runner that lists the certificate when `listed` is set and answers `security`'s partition
    /// change with `status`.
    private func runner(listed: Bool = true, status: Int32 = 0) -> FakeRunner {
        FakeRunner { command in
            guard command.arguments.first == "set-key-partition-list" else {
                return CommandResult(status: 0, output: listed ? SigningCertificateTests.listed : "")
            }
            return CommandResult(status: status, errors: "wrong password\n")
        }
    }

    private func allow(_ runner: FakeRunner, canAsk: Bool = true) async -> [Message] {
        let certificate = SigningCertificate(runner: runner, files: files, paths: paths, temporaryDirectory: "/tmp")
        var messages: [Message] = []
        await SigningKeyAccess(runner: runner, state: state, paths: paths, certificate: certificate)
            .allow(canAsk: canAsk) { messages.append($0) }
        return messages
    }

    private func partitionChanges(_ runner: FakeRunner) -> [Command] {
        runner.commands.filter { $0.arguments.first == "set-key-partition-list" }
    }

    @Test func firstRunAsksOnceAndNotesTheCertificate() async throws {
        let runner = runner()
        let messages = await allow(runner)
        #expect(
            partitionChanges(runner) == [
                Security.allowAppleTools(key: SigningCertificate.name, keychain: paths.loginKeychain)
            ])
        #expect(try state.read(SigningKeyAccess.noteName) == Self.hash)
        #expect(messages == [.askingForLoginPassword, .signingKeyAllowed])
    }

    @Test func notedCertificateIsLeftAlone() async throws {
        try state.write(Self.hash, to: SigningKeyAccess.noteName)
        let runner = runner()
        #expect(await allow(runner).isEmpty)
        #expect(partitionChanges(runner).isEmpty)
    }

    @Test func newCertificateAsksAgain() async throws {
        try state.write("0000000000000000000000000000000000000000", to: SigningKeyAccess.noteName)
        let runner = runner()
        _ = await allow(runner)
        #expect(partitionChanges(runner).count == 1)
        #expect(try state.read(SigningKeyAccess.noteName) == Self.hash)
    }

    @Test func noCertificateYetDoesNothing() async {
        let runner = runner(listed: false)
        #expect(await allow(runner).isEmpty)
        #expect(partitionChanges(runner).isEmpty)
    }

    @Test func withoutTerminalItWarns() async throws {
        let runner = runner()
        #expect(await allow(runner, canAsk: false) == [.signingKeyNeedsTerminal])
        #expect(partitionChanges(runner).isEmpty)
        #expect(try state.read(SigningKeyAccess.noteName) == nil)
    }

    @Test func refusedPasswordWarnsAndAsksNextTime() async throws {
        let runner = runner(status: 1)
        #expect(await allow(runner) == [.askingForLoginPassword, .signingKeyStillAsks(reason: "wrong password")])
        #expect(try state.read(SigningKeyAccess.noteName) == nil)
    }
}
