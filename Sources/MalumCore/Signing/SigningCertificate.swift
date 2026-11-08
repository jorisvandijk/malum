import Foundation

/// Malum's own code signing certificate, in the login keychain.
///
/// macOS ties each permission it grants to the app's signature. Releases are signed ad hoc, which
/// gives every build a new one, so Malum signs itself with a certificate of its own that stays the
/// same for good.
public struct SigningCertificate: Sendable {
    /// The certificate's name in the keychain.
    public static let name = "\(Project.name) code signing"

    /// Runs `security` and `openssl`.
    private let runner: any CommandRunner
    /// Where the files that make the certificate are written for a moment.
    private let files: any FileSystem
    /// Where Malum's own files go, including the login keychain.
    private let paths: Paths
    /// A folder only the user can read, for the key on its way into the keychain.
    private let temporaryDirectory: String

    /// Creates access to the certificate. The key is written to `temporaryDirectory` for a moment.
    public init(runner: any CommandRunner, files: any FileSystem, paths: Paths, temporaryDirectory: String) {
        self.runner = runner
        self.files = files
        self.paths = paths
        self.temporaryDirectory = temporaryDirectory
    }

    /// The certificate's SHA-1, or nil when the keychain doesn't have it.
    public func find() async -> String? {
        let result = await runner.run(Security.findIdentities())
        guard result.succeeded else { return nil }
        return Security.identity(named: Self.name, in: result.output)
    }

    /// Makes the certificate, adds it to the login keychain and returns its SHA-1. The files it
    /// takes are removed again, whatever happens.
    public func create() async throws(SigningError) -> String {
        let folder = "\(temporaryDirectory)/\(Project.command)-signing-\(UUID().uuidString)"
        do {
            try files.createDirectory(folder)
            try files.write(Self.config, to: "\(folder)/openssl.cnf")
        } catch {
            throw .files(error)
        }
        defer { try? files.remove(folder) }  // A leftover folder in the temporary folder is harmless.
        for (step, command) in steps(in: folder) {
            let result = await runner.run(command)
            guard result.succeeded else { throw .uncreatable(step: step, reason: result.reason) }
        }
        guard let identity = await find() else { throw .unlisted }
        return identity
    }

    /// The steps that make the certificate from the files in `folder`, with what each one does.
    private func steps(in folder: String) -> [(String, Command)] {
        let key = "\(folder)/key.pem"
        let certificate = "\(folder)/certificate.pem"
        let bundle = "\(folder)/identity.p12"
        // The password only protects the file on its way into the keychain.
        let password = UUID().uuidString
        return [
            (
                Self.makeStep,
                OpenSSL.makeCertificate(key: key, certificate: certificate, config: "\(folder)/openssl.cnf")
            ),
            (
                Self.bundleStep,
                OpenSSL.bundle(key: key, certificate: certificate, name: Self.name, password: password, output: bundle)
            ),
            (
                Self.keychainStep,
                Security.importIdentity(bundle, password: password, keychain: paths.loginKeychain)
            ),
        ]
    }

    /// What `openssl` puts in the certificate: a code signing certificate that isn't a CA.
    static let config = """
        [req]
        distinguished_name = dn
        prompt = no

        [dn]
        CN = \(name)

        [ext]
        basicConstraints = critical, CA:false
        keyUsage = critical, digitalSignature
        extendedKeyUsage = critical, codeSigning

        """
}
