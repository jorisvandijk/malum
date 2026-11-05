/// Makes sure the installed Malum is signed with its own certificate before anything starts.
///
/// No module starts and no permission is asked for until this says `signed`. The first start of
/// a new install signs the app in place and restarts it through launchd.
public struct SelfSigning: Sendable {
    /// Runs `launchctl`.
    private let runner: any CommandRunner
    /// Compares the running executable with the installed one.
    private let files: any FileSystem
    /// Where the installed app and the login agent are.
    private let paths: Paths
    /// The certificate in the login keychain.
    private let certificate: SigningCertificate
    /// Signs the bundle.
    private let signer: BundleSigner

    /// Creates the check for the installed app.
    public init(runner: any CommandRunner, files: any FileSystem, paths: Paths, certificate: SigningCertificate) {
        self.runner = runner
        self.files = files
        self.paths = paths
        self.certificate = certificate
        signer = BundleSigner(runner: runner, files: files)
    }

    /// Checks the app that runs `executable`, which has its links resolved and is nil outside an
    /// app bundle. An installed app that isn't signed with the certificate is signed in place,
    /// with the certificate made first when the keychain doesn't have it.
    public func check(executable: String?) async -> SigningOutcome {
        guard paths.isInstalled(executable: executable, files: files) else { return .notInstalled }
        let bundle = files.canonicalPath(paths.installedBundle)
        let found = await certificate.find()
        if let found, await signer.isSigned(bundle, by: found) {
            return .signed
        }
        do {
            let identity: String
            if let found {
                identity = found
            } else {
                identity = try await certificate.create()
            }
            try await signer.install(bundle, at: bundle, identity: identity)
        } catch {
            return .failed(error)
        }
        return .resigned
    }

    /// Starts the signed app through launchd, for the user with id `userID`: the login agent is
    /// restarted when it's loaded, and loaded, which starts it, when it isn't. The app that asks
    /// should quit straight after, so the new one can take its place.
    public func restart(userID: UInt32) async throws(SigningError) {
        let service = Launchctl.service(Project.bundleID, userID: userID)
        let loaded = await runner.run(Launchctl.describe(service)).succeeded
        let command =
            loaded
            ? Launchctl.restart(service) : Launchctl.load(paths.loginAgent, into: Launchctl.domain(userID: userID))
        let result = await runner.run(command)
        guard result.succeeded else { throw .unrestartable(reason: result.reason) }
    }
}
