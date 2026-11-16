/// Lets codesign use Malum's signing key without the keychain asking, so signing Malum after an
/// update, or a web app, shows no "Always Allow" prompt.
///
/// Which tools may use a key without asking is the key's partition list, and changing it takes the
/// login password once, on the terminal. A note in the state folder says which certificate it was
/// done for, so a new certificate gets it again.
@MainActor
public struct SigningKeyAccess {
    /// The note in the state folder, holding the certificate's SHA-1.
    static let noteName = "signing-key-access"

    /// Runs `security`.
    private let runner: any CommandRunner
    /// Holds the note.
    private let state: StateFolder
    /// Where the login keychain is.
    private let paths: Paths
    /// The certificate whose key it is.
    private let certificate: SigningCertificate

    /// Creates the step for `certificate`'s key in the login keychain.
    public init(runner: any CommandRunner, state: StateFolder, paths: Paths, certificate: SigningCertificate) {
        self.runner = runner
        self.state = state
        self.paths = paths
        self.certificate = certificate
    }

    /// Lets codesign use the key, once per certificate. Asks for the password only when `canAsk`
    /// is set. Nothing happens before the app has made the certificate.
    public func allow(canAsk: Bool, report: (Message) -> Void) async {
        guard let identity = await certificate.find() else { return }
        do {
            guard try state.read(Self.noteName) != identity else { return }
        } catch {
            report(.warning(error))
            return
        }
        guard canAsk else {
            report(.signingKeyNeedsTerminal)
            return
        }
        report(.askingForLoginPassword)
        let result = await runner.run(
            Security.allowAppleTools(key: SigningCertificate.name, keychain: paths.loginKeychain))
        guard result.succeeded else {
            report(.signingKeyStillAsks(reason: result.reason))
            return
        }
        do {
            try state.write(identity, to: Self.noteName)
        } catch {
            report(.warning(error))
            return
        }
        report(.signingKeyAllowed)
    }
}
