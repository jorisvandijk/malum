import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct BundleSignerTests {
    let app = "/Users/test/Applications/Malum.app"
    let staged = "/Users/test/Applications/Malum.app.staged"
    let plist = "/Users/test/Applications/Malum.app/Contents/Info.plist"
    let tool = "/Users/test/Applications/Malum.app/Contents/Helpers/rcodesign"
    let identity = SigningCertificateTests.identity

    @Test func installSignsAStagedCopyAndSwapsItIn() async throws {
        let files = FakeFileSystem(texts: [plist: "old"])
        let runner = FakeRunner()
        try await BundleSigner(runner: runner, files: files, tool: tool).install(app, at: app, identity: identity)
        #expect(
            runner.commands == [
                Rcodesign.sign(staged, identity: identity, tool: tool),
                Codesign.verify(staged, identity: identity.hash),
            ])
        #expect(files.text(at: plist) == "old")
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func leftoverStagingIsReplaced() async throws {
        let files = FakeFileSystem(texts: [plist: "old", "\(staged)/junk": "junk"])
        try await BundleSigner(runner: FakeRunner(), files: files, tool: tool).install(app, at: app, identity: identity)
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func failedSigningKeepsTheAppAndCleansUp() async {
        let files = FakeFileSystem(texts: [plist: "old"])
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "no identity found\n") }
        await #expect(throws: SigningError.unsigned(reason: "no identity found")) {
            try await BundleSigner(runner: runner, files: files, tool: tool).install(app, at: app, identity: identity)
        }
        #expect(runner.commands.count == 1)
        #expect(files.text(at: plist) == "old")
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func failedCheckNeverSwaps() async {
        let files = FakeFileSystem(texts: [plist: "old"])
        let runner = FakeRunner { command in
            command.arguments.first == "--verify"
                ? CommandResult(status: 1, errors: "invalid signature\n") : CommandResult(status: 0)
        }
        await #expect(throws: SigningError.unverified(reason: "invalid signature")) {
            try await BundleSigner(runner: runner, files: files, tool: tool).install(app, at: app, identity: identity)
        }
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func failedSwapIsReported() async {
        let files = FakeFileSystem(texts: [plist: "old"], failing: [app])
        await #expect(throws: SigningError.files(.unswappable(path: staged, other: app, reason: "can't swap"))) {
            try await BundleSigner(runner: FakeRunner(), files: files, tool: tool).install(
                app, at: app, identity: identity)
        }
        #expect(files.text(at: plist) == "old")
    }

    @Test func signatureIsCheckedAgainstTheCertificate() async {
        let runner = FakeRunner { _ in CommandResult(status: 1) }
        #expect(await !BundleSigner(runner: runner, files: FakeFileSystem(), tool: tool).isSigned(app, by: identity))
        #expect(runner.commands == [Codesign.verify(app, identity: identity.hash)])
    }
}
