/// A config file an app reads, written by system config from the app's file in dots.
public struct AppFile: Equatable, Sendable {
    /// Where the file goes, relative to the home folder, such as `.config/git/config`.
    public let path: String
    /// What the file holds.
    public let text: String

    /// Creates the file at `path`, relative to the home folder, holding `text`.
    public init(_ path: String, _ text: String) {
        self.path = path
        self.text = text
    }
}
