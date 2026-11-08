/// Why an update or a rollback of Malum itself failed.
public enum UpdateError: Error, Equatable, Sendable {
    /// The latest release's tag isn't a version.
    case unreadableTag(String)
    /// The latest release doesn't have the file.
    case missingAsset(name: String, tag: String)
    /// `shasum` couldn't check the download.
    case uncheckable(reason: String)
    /// The download's checksum isn't the one the release gives.
    case checksumMismatch(name: String)
    /// The download couldn't be unpacked.
    case unpackable(reason: String)
    /// The download doesn't hold the app.
    case noApp(name: String)
    /// The downloaded app has another bundle ID, or none.
    case otherApp(bundleID: String?)
    /// The downloaded app says it's another version than its tag.
    case wrongVersion(expected: String, found: String)
    /// The login keychain doesn't have Malum's certificate.
    case noCertificate
    /// No previous version is kept to roll back to.
    case nothingKept
    /// The kept version isn't signed with Malum's certificate anymore.
    case keptUnsigned
}
