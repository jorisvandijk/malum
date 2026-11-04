import Synchronization

@testable import MalumCore

/// GitHub held in memory: each repository's latest release, and the files a download writes.
final class FakeGitHub: GitHub {
    /// The latest release of each repository.
    let releases: [String: Release]
    /// Where downloads are written.
    let files: FakeFileSystem
    /// Every asset downloaded, in order.
    private let fetched = Mutex<[String]>([])

    init(_ releases: [String: Release], files: FakeFileSystem) {
        self.releases = releases
        self.files = files
    }

    var downloads: [String] { fetched.withLock { $0 } }

    func latestRelease(of repo: String) async throws(GitHubError) -> Release? {
        guard repo != "down/down" else { throw .refused(status: 503) }
        return releases[repo]
    }

    func download(_ asset: ReleaseAsset, to path: String) async throws(GitHubError) {
        fetched.withLock { $0.append(asset.name) }
        do {
            try files.write(asset.url, to: path)
        } catch {
            throw .unsaved(path: path, reason: "read-only")
        }
    }
}
