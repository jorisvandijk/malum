/// A config file an app reads, written by system config from the app's file in dots.
public struct AppFile: Equatable, Sendable {
    /// Where the file goes, relative to the home folder, such as `.config/git/config`.
    public let path: String
    /// What the file holds.
    public let text: String
    /// Whether the file is written only when there's none, and left to the app after that.
    public let onlyWhenMissing: Bool

    /// Creates the file at `path`, relative to the home folder, holding `text`, written only when
    /// there's none yet when it's `onlyWhenMissing`.
    public init(_ path: String, _ text: String, onlyWhenMissing: Bool = false) {
        self.path = path
        self.text = text
        self.onlyWhenMissing = onlyWhenMissing
    }
}
