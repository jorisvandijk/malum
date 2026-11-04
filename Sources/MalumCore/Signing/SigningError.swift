/// Why signing Malum with its own certificate failed.
public enum SigningError: Error, Equatable, Sendable {
    /// A step of making the certificate failed, with what the step was and why.
    case uncreatable(step: String, reason: String)
    /// The certificate was added to the keychain, but codesign doesn't list it.
    case unlisted
    /// The copy of the app couldn't be made or put in place.
    case files(FileSystemError)
    /// codesign couldn't sign the copy.
    case unsigned(reason: String)
    /// The signed copy didn't pass codesign's check.
    case unverified(reason: String)
    /// launchd couldn't start the signed app.
    case unrestartable(reason: String)
}

// MARK: - ReportableError

extension SigningError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .uncreatable(let step, let reason):
            "couldn't \(step) for the \"\(SigningCertificate.name)\" certificate: \(reason)"
        case .unlisted:
            "added the \"\(SigningCertificate.name)\" certificate to the login keychain, but codesign doesn't list it"
        case .files(let error):
            error.text
        case .unsigned(let reason):
            "couldn't sign \(Project.name) with the \"\(SigningCertificate.name)\" certificate: \(reason)"
        case .unverified(let reason):
            "the signed copy of \(Project.name) didn't pass codesign's check: \(reason)"
        case .unrestartable(let reason):
            "signed \(Project.name), but couldn't restart it: \(reason); quit it and open it again"
        }
    }
}
