/// A file attached to a GitHub release.
public struct ReleaseAsset: Equatable, Sendable {
    /// The file's name.
    public let name: String
    /// The API link it downloads from, which works for private repositories too.
    public let url: String

    /// Creates the file called `name`, which downloads from `url`.
    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

/// A published GitHub release.
public struct Release: Equatable, Sendable {
    /// Its tag, such as `v0.40.0`.
    public let tag: String
    /// The files attached to it.
    public let assets: [ReleaseAsset]

    /// Creates the release tagged `tag`, with `assets`.
    public init(tag: String, assets: [ReleaseAsset]) {
        self.tag = tag
        self.assets = assets
    }
}

/// GitHub's releases, behind a protocol so tests never touch the network.
public protocol GitHub: Sendable {
    /// The latest published release of `repo` (`owner/name`), or nil when the repository has none
    /// or can't be seen.
    func latestRelease(of repo: String) async throws(GitHubError) -> Release?
    /// Downloads `asset` to a new file at `path`.
    func download(_ asset: ReleaseAsset, to path: String) async throws(GitHubError)
    /// Checks that `token` can read `repo` (`owner/name`), and throws when GitHub refuses it.
    func check(_ token: String, canRead repo: String) async throws(GitHubError)
}
