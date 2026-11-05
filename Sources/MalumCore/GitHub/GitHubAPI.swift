import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// The real GitHub, over its public API. It has no token yet, so it sees only public repositories,
/// and GitHub allows it 60 lookups an hour.
public struct GitHubAPI: GitHub {
    /// The API's address.
    private static let api = "https://api.github.com"
    /// The HTTP status of an answer that worked.
    private static let ok = 200
    /// The HTTP status for a repository or release that doesn't exist.
    private static let notFound = 404

    /// Creates access to GitHub.
    public init() {}

    /// Asks the API for the repository's latest release.
    public func latestRelease(of repo: String) async throws(GitHubError) -> Release? {
        let (status, data) = try await fetch(
            "\(Self.api)/repos/\(repo)/releases/latest", accept: "application/vnd.github+json")
        guard status != Self.notFound else { return nil }
        guard status == Self.ok else { throw .refused(status: status) }
        let answer: Answer
        do {
            answer = try JSONDecoder().decode(Answer.self, from: data)
        } catch {
            throw .unreadable
        }
        return Release(
            tag: answer.tagName, assets: answer.assets.map { ReleaseAsset(name: $0.name, url: $0.browserDownloadURL) })
    }

    /// Downloads the file and writes it to `path`.
    public func download(_ asset: ReleaseAsset, to path: String) async throws(GitHubError) {
        let (status, data) = try await fetch(asset.url, accept: "application/octet-stream")
        guard status == Self.ok else { throw .refused(status: status) }
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            throw .unsaved(path: path, reason: error.localizedDescription)
        }
    }

    /// Sends a GET to `address`, and gives back the HTTP status and the body.
    private func fetch(_ address: String, accept: String) async throws(GitHubError) -> (Int, Data) {
        guard let url = URL(string: address) else { throw .unreachable(reason: "\(address) isn't a link") }
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(Project.command, forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return ((response as? HTTPURLResponse)?.statusCode ?? 0, data)
        } catch {
            throw .unreachable(reason: error.localizedDescription)
        }
    }
}

/// The parts of the API's answer about a release that Malum reads.
private struct Answer: Decodable {
    /// The release's tag.
    let tagName: String
    /// The attached files.
    let assets: [AnswerAsset]

    /// The API's names for the fields.
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

/// One file attached to a release, in the API's answer.
private struct AnswerAsset: Decodable {
    /// The file's name.
    let name: String
    /// Where it downloads from.
    let browserDownloadURL: String

    /// The API's names for the fields.
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
