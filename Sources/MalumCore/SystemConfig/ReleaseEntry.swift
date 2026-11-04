/// A program or app from a GitHub release, as `[release.<name>]` in `packages.toml` lists it.
public struct ReleaseEntry: Equatable, Sendable {
    /// The name it has in `packages.toml`, which is also the name a program is installed under.
    public let name: String
    /// The repository, as `owner/name`.
    public let repo: String
    /// The name of the file to install from the release, where `*` matches any text, or nil to pick
    /// the only file that fits.
    public let asset: String?

    /// Creates the entry `name`, from the releases of `repo`, installing the file `asset` matches.
    public init(_ name: String, repo: String, asset: String? = nil) {
        self.name = name
        self.repo = repo
        self.asset = asset
    }
}
