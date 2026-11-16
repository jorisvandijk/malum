import Foundation

/// Malum's own code signing certificate and key, in a file only the user can read.
///
/// macOS ties each permission it grants to the app's signature. Releases are signed ad hoc, which
/// gives every build a new one, so Malum signs itself with a certificate of its own that stays the
/// same for good. The key lives in a file, not the keychain, so signing never asks for anything.
public struct SigningCertificate: Sendable {
    /// The certificate's name.
    public static let name = "\(Project.name) code signing"

    /// Runs `openssl` and `csreq`.
    private let runner: any CommandRunner
    /// Holds the key file and the files that make it.
    private let files: any FileSystem
    /// Where the key file and the requirement go.
    private let paths: Paths
    /// A folder only the user can read, for the key while it's made.
    private let temporaryDirectory: String

    /// Creates access to the certificate. The key is made in `temporaryDirectory`.
    public init(runner: any CommandRunner, files: any FileSystem, paths: Paths, temporaryDirectory: String) {
        self.runner = runner
        self.files = files
        self.paths = paths
        self.temporaryDirectory = temporaryDirectory
    }

    /// The identity in the key file, or nil when there's no key file or requirement yet.
    public func find() async -> SigningIdentity? {
        guard files.item(at: paths.signingKey) != nil, files.item(at: paths.signingRequirement) != nil else {
            return nil
        }
        guard let hash = await fingerprint() else { return nil }
        return SigningIdentity(hash: hash, keyFile: paths.signingKey, requirement: paths.signingRequirement)
    }

    /// Makes the certificate and its key, keeps them in the key file, compiles the designated
    /// requirement that pins the certificate, and returns the identity. The files it takes on the
    /// way are removed again, whatever happens.
    public func create() async throws(SigningError) -> SigningIdentity {
        let folder = "\(temporaryDirectory)/\(Project.command)-signing-\(UUID().uuidString)"
        let key = "\(folder)/key.pem"
        let certificate = "\(folder)/certificate.pem"
        do {
            try files.createPrivateDirectory(folder)
            try files.write(Self.config, to: "\(folder)/openssl.cnf")
        } catch {
            throw .files(error)
        }
        defer { try? files.remove(folder) }  // A leftover folder in the temporary folder is harmless.
        let made = await runner.run(
            OpenSSL.makeCertificate(key: key, certificate: certificate, config: "\(folder)/openssl.cnf"))
        guard made.succeeded else { throw .uncreatable(step: Self.makeStep, reason: made.reason) }
        try keep(certificate: certificate, key: key)
        guard let hash = await fingerprint() else { throw .unlisted }
        let compiled = await runner.run(Csreq.designated(certificate: hash, output: paths.signingRequirement))
        guard compiled.succeeded else { throw .uncreatable(step: Self.requirementStep, reason: compiled.reason) }
        return SigningIdentity(hash: hash, keyFile: paths.signingKey, requirement: paths.signingRequirement)
    }

    /// Puts the certificate, then its key, in the key file, readable only by the user.
    private func keep(certificate: String, key: String) throws(SigningError) {
        do {
            let identity = try files.read(certificate) + files.read(key)
            try files.createDirectory(paths.configDirectory)
            try files.writePrivate(Data(identity.utf8), to: paths.signingKey)
        } catch {
            throw .files(error)
        }
    }

    /// The SHA-1 of the certificate in the key file.
    private func fingerprint() async -> String? {
        let result = await runner.run(OpenSSL.fingerprint(paths.signingKey))
        guard result.succeeded else { return nil }
        return OpenSSL.sha1(in: result.output)
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
