import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct BundleSignerTests {
    let app = "/Users/joris/Applications/Malum.app"
    let staged = "/Users/joris/Applications/Malum.app.staged"
    let plist = "/Users/joris/Applications/Malum.app/Contents/Info.plist"

    @Test func installSignsAStagedCopyAndSwapsItIn() async throws {
        let files = FakeFileSystem(texts: [plist: "old"])
        let runner = FakeRunner()
        try await BundleSigner(runner: runner, files: files).install(app, at: app, identity: "ID")
        #expect(runner.commands == [Codesign.sign(staged, identity: "ID"), Codesign.verify(staged, identity: "ID")])
        #expect(files.text(at: plist) == "old")
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func leftoverStagingIsReplaced() async throws {
        let files = FakeFileSystem(texts: [plist: "old", "\(staged)/junk": "junk"])
        try await BundleSigner(runner: FakeRunner(), files: files).install(app, at: app, identity: "ID")
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func failedSigningKeepsTheAppAndCleansUp() async {
        let files = FakeFileSystem(texts: [plist: "old"])
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "no identity found\n") }
        await #expect(throws: SigningError.unsigned(reason: "no identity found")) {
            try await BundleSigner(runner: runner, files: files).install(app, at: app, identity: "ID")
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
            try await BundleSigner(runner: runner, files: files).install(app, at: app, identity: "ID")
        }
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix(staged) })
    }

    @Test func failedSwapIsReported() async {
        let files = FakeFileSystem(texts: [plist: "old"], failing: [app])
        await #expect(throws: SigningError.files(.unswappable(path: staged, other: app, reason: "can't swap"))) {
            try await BundleSigner(runner: FakeRunner(), files: files).install(app, at: app, identity: "ID")
        }
        #expect(files.text(at: plist) == "old")
    }

    @Test func signatureIsCheckedAgainstTheCertificate() async {
        let runner = FakeRunner { _ in CommandResult(status: 1) }
        #expect(await !BundleSigner(runner: runner, files: FakeFileSystem()).isSigned(app, by: "ID"))
        #expect(runner.commands == [Codesign.verify(app, identity: "ID")])
    }
}
