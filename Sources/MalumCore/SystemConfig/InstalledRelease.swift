/// A release Malum installed, as the record of what Malum installed keeps it.
public struct InstalledRelease: Codable, Equatable, Sendable {
    /// The repository it came from.
    public let repo: String
    /// The release's tag.
    public let tag: String
    /// Where it was installed: the program, or the `.app`.
    public let path: String

    /// Creates the record of the release `tag` of `repo`, installed at `path`.
    public init(repo: String, tag: String, path: String) {
        self.repo = repo
        self.tag = tag
        self.path = path
    }
}
