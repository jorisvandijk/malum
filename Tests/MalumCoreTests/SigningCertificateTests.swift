import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SigningCertificateTests {
    static let hash = "3F2A1B0C9D8E7F6A5B4C3D2E1F0A9B8C7D6E5F40"
    /// What `openssl x509 -fingerprint -sha1` prints for the certificate.
    static let fingerprint = "SHA1 Fingerprint=3F:2A:1B:0C:9D:8E:7F:6A:5B:4C:3D:2E:1F:0A:9B:8C:7D:6E:5F:40\n"
    static let paths = Paths(home: "/Users/test")
    /// The identity in the key file, once there is one.
    static let identity = SigningIdentity(
        hash: hash, keyFile: paths.signingKey, requirement: paths.signingRequirement)

    /// Puts a key file and a requirement in `files`, as the first start leaves them.
    static func keep(in files: FakeFileSystem) {
        try? files.write("CERTIFICATE KEY", to: paths.signingKey)  // The fake only fails paths it's told to.
        try? files.write("REQUIREMENT", to: paths.signingRequirement)
    }

    /// Whether `command` reads the certificate's fingerprint.
    static func readsFingerprint(_ command: Command) -> Bool { command.arguments.first == "x509" }

    private func certificate(_ runner: FakeRunner, files: FakeFileSystem) -> SigningCertificate {
        SigningCertificate(runner: runner, files: files, paths: Self.paths, temporaryDirectory: "/tmp")
    }

    @Test func keptKeyIsFound() async {
        let files = FakeFileSystem()
        Self.keep(in: files)
        let runner = FakeRunner { _ in CommandResult(status: 0, output: Self.fingerprint) }
        #expect(await certificate(runner, files: files).find() == Self.identity)
    }

    @Test func missingKeyIsNil() async {
        let runner = FakeRunner { _ in CommandResult(status: 0, output: Self.fingerprint) }
        #expect(await certificate(runner, files: FakeFileSystem()).find() == nil)
        #expect(runner.commands.isEmpty)
    }

    @Test func createKeepsCertificateAndKeyPrivatelyAndCompilesTheRequirement() async throws {
        let files = FakeFileSystem()
        let runner = FakeRunner { command in
            guard command.arguments.first == "req" else { return CommandResult(status: 0, output: Self.fingerprint) }
            let arguments = command.arguments
            guard let key = arguments.firstIndex(of: "-keyout"), let out = arguments.firstIndex(of: "-out") else {
                return CommandResult(status: 1)
            }
            try? files.write("KEY\n", to: arguments[key + 1])
            try? files.write("CERTIFICATE\n", to: arguments[out + 1])
            return CommandResult(status: 0)
        }
        #expect(try await certificate(runner, files: files).create() == Self.identity)
        #expect(runner.commands.map(\.executable) == ["/usr/bin/openssl", "/usr/bin/openssl", "/usr/bin/csreq"])
        #expect(
            runner.commands.last
                == Csreq.designated(certificate: Self.hash, output: Self.paths.signingRequirement))
        #expect(files.text(at: Self.paths.signingKey) == "CERTIFICATE\nKEY\n")
        #expect(files.isPrivate(Self.paths.signingKey))
        #expect(files.allPaths.allSatisfy { !$0.hasPrefix("/tmp") })
    }

    @Test func failedStepStopsAndCleansUp() async {
        let files = FakeFileSystem()
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "bad config\n") }
        await #expect(throws: SigningError.uncreatable(step: "make the certificate", reason: "bad config")) {
            try await certificate(runner, files: files).create()
        }
        #expect(runner.commands.count == 1)
        #expect(files.allPaths.isEmpty)
    }

    @Test func configMakesACodeSigningCertificate() {
        #expect(SigningCertificate.config.contains("CN = Malum code signing"))
        #expect(SigningCertificate.config.contains("extendedKeyUsage = critical, codeSigning"))
    }
}
