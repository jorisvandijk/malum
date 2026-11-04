import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SigningCertificateTests {
    static let hash = "3F2A1B0C9D8E7F6A5B4C3D2E1F0A9B8C7D6E5F40"
    static let listed = "  1) \(hash) \"Malum code signing\" (CSSMERR_TP_NOT_TRUSTED)\n"
    let paths = Paths(home: "/Users/joris")

    private func certificate(_ runner: FakeRunner, files: FakeFileSystem = FakeFileSystem()) -> SigningCertificate {
        SigningCertificate(runner: runner, files: files, paths: paths, temporaryDirectory: "/tmp")
    }

    @Test func listedCertificateIsFound() async {
        let runner = FakeRunner { _ in CommandResult(status: 0, output: Self.listed) }
        #expect(await certificate(runner).find() == Self.hash)
    }

    @Test func missingCertificateIsNil() async {
        let runner = FakeRunner { _ in CommandResult(status: 0, output: "0 valid identities found\n") }
        #expect(await certificate(runner).find() == nil)
    }

    @Test func createMakesBundlesImportsAndFinds() async throws {
        let files = FakeFileSystem()
        let runner = FakeRunner { _ in CommandResult(status: 0, output: Self.listed) }
        #expect(try await certificate(runner, files: files).create() == Self.hash)
        let steps = runner.commands.map { $0.arguments.first }
        #expect(steps == ["req", "pkcs12", "import", "find-identity"])
        #expect(runner.commands[2].arguments.contains(paths.loginKeychain))
        #expect(files.allPaths.isEmpty)
    }

    @Test func failedStepStopsAndCleansUp() async {
        let files = FakeFileSystem()
        let runner = FakeRunner { command in
            command.arguments.first == "pkcs12"
                ? CommandResult(status: 1, errors: "bad cipher\n") : CommandResult(status: 0)
        }
        await #expect(throws: SigningError.uncreatable(step: "bundle it", reason: "bad cipher")) {
            try await certificate(runner, files: files).create()
        }
        #expect(runner.commands.count == 2)
        #expect(files.allPaths.isEmpty)
    }

    @Test func importedButUnlistedIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 0) }
        await #expect(throws: SigningError.unlisted) { try await certificate(runner).create() }
    }

    @Test func configMakesACodeSigningCertificate() {
        #expect(SigningCertificate.config.contains("CN = Malum code signing"))
        #expect(SigningCertificate.config.contains("extendedKeyUsage = critical, codeSigning"))
    }
}
