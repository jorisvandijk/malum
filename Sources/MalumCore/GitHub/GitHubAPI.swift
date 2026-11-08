import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// The real GitHub, over its API. With a token it also sees the private repositories the token can
/// read, and GitHub allows it 5000 lookups an hour instead of 60.
public struct GitHubAPI: GitHub {
    /// The API's host.
    private static let host = "api.github.com"
    /// The API's address.
    private static let api = "https://\(host)"
    /// What the API answers in.
    private static let json = "application/vnd.github+json"
    /// The HTTP status of an answer that worked.
    private static let ok = 200
    /// The HTTP status for a token GitHub refuses.
    private static let unauthorized = 401
    /// The HTTP status for a repository the token isn't allowed to read.
    private static let forbidden = 403
    /// The HTTP status for a repository or release that doesn't exist, or can't be seen.
    private static let notFound = 404
    /// The header that carries the token.
    private static let authorization = "Authorization"
    /// Follows GitHub's redirects to a download without the token.
    private static let session = URLSession(
        configuration: .ephemeral, delegate: RedirectWithoutToken(), delegateQueue: nil)

    /// The token sent with every request, or nil to ask without one.
    private let token: String?

    /// Creates access to GitHub, sending `token` with every request when there is one.
    public init(token: String?) {
        self.token = token
    }

    /// Asks the API for the repository's latest release.
    public func latestRelease(of repo: String) async throws(GitHubError) -> Release? {
        let (status, data) = try await fetch("\(Self.api)/repos/\(repo)/releases/latest", accept: Self.json)
        guard status != Self.notFound else {
            guard token != nil || repo != Project.repository else { throw .needsToken(repo: repo) }
            return nil
        }
        guard status == Self.ok else { throw .refused(status: status) }
        let answer: Answer
        do {
            answer = try JSONDecoder().decode(Answer.self, from: data)
        } catch {
            throw .unreadable
        }
        return Release(tag: answer.tagName, assets: answer.assets.map { ReleaseAsset(name: $0.name, url: $0.url) })
    }

    /// Downloads the file through the API, which redirects to a signed link, and writes it to `path`.
    public func download(_ asset: ReleaseAsset, to path: String) async throws(GitHubError) {
        let (status, data) = try await fetch(asset.url, accept: "application/octet-stream")
        guard status == Self.ok else { throw .refused(status: status) }
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            throw .unsaved(path: path, reason: error.localizedDescription)
        }
    }

    /// Asks the API for the repository with `token`.
    public func check(_ token: String, canRead repo: String) async throws(GitHubError) {
        let (status, _) = try await GitHubAPI(token: token).fetch("\(Self.api)/repos/\(repo)", accept: Self.json)
        switch status {
        case Self.ok:
            return
        case Self.forbidden, Self.notFound:
            throw .tokenCantRead(repo: repo)
        default:
            throw .refused(status: status)
        }
    }

    /// `request`, a redirect, without the token when it leads away from the API, such as to the
    /// signed link of a download, which doesn't need it.
    static func redirect(_ request: URLRequest) -> URLRequest {
        guard request.url?.host != host else { return request }
        var stripped = request
        stripped.setValue(nil, forHTTPHeaderField: authorization)
        return stripped
    }

    /// Sends a GET to `address`, and gives back the HTTP status and the body.
    private func fetch(_ address: String, accept: String) async throws(GitHubError) -> (Int, Data) {
        guard let url = URL(string: address) else { throw .notALink(address: address) }
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(Project.command, forHTTPHeaderField: "User-Agent")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: Self.authorization) }
        let status: Int
        let data: Data
        do {
            let (body, response) = try await Self.session.data(for: request)
            status = (response as? HTTPURLResponse)?.statusCode ?? 0
            data = body
        } catch {
            throw .unreachable(reason: error.localizedDescription)
        }
        guard status != Self.unauthorized || token == nil else { throw .tokenRefused }
        return (status, data)
    }
}

/// Drops the token when GitHub redirects a download to its signed storage link.
private final class RedirectWithoutToken: NSObject, URLSessionTaskDelegate, Sendable {
    /// Follows the redirect, without the token when it leaves the API.
    func urlSession(
        _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(GitHubAPI.redirect(request))
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
    /// The API link it downloads from.
    let url: String
}
