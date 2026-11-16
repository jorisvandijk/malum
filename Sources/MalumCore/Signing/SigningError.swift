/// Why signing Malum with its own certificate failed.
public enum SigningError: Error, Equatable, Sendable {
    /// A step of making the certificate failed, with what the step was and why.
    case uncreatable(step: String, reason: String)
    /// The key file was written, but its certificate can't be read back.
    case unlisted
    /// The copy of the app couldn't be made or put in place.
    case files(FileSystemError)
    /// rcodesign couldn't sign the copy.
    case unsigned(reason: String)
    /// The signed copy didn't pass codesign's check.
    case unverified(reason: String)
    /// launchd couldn't start the signed app.
    case unrestartable(reason: String)
}
