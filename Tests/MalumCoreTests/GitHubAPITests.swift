import Foundation
import Testing

@testable import MalumCore

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite(.timeLimit(.minutes(1)))
struct GitHubAPITests {
    /// A request to `address` that carries a token.
    private func request(_ address: String) throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: address)))
        request.setValue("Bearer good", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        return request
    }

    @Test func redirectAwayFromTheAPIDropsTheToken() throws {
        let redirect = GitHubAPI.redirect(try request("https://objects.githubusercontent.com/asset?signature=x"))
        #expect(redirect.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(redirect.value(forHTTPHeaderField: "Accept") == "application/octet-stream")
    }

    @Test func redirectWithinTheAPIKeepsTheToken() throws {
        let redirect = GitHubAPI.redirect(try request("https://api.github.com/repositories/1/releases/latest"))
        #expect(redirect.value(forHTTPHeaderField: "Authorization") == "Bearer good")
    }
}
