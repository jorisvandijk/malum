import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ProjectTests {
    @Test func bundleIDIsReverseDNSEndingInCommand() {
        let parts = Project.bundleID.split(separator: ".")
        #expect(parts.count >= 3)
        #expect(parts.last.map(String.init) == Project.command)
    }

    @Test func commandIsLowercasedName() {
        #expect(Project.command == Project.name.lowercased())
    }

    @Test func repositoryURLIsHTTPS() {
        #expect(URL(string: Project.repositoryURL)?.scheme == "https")
    }

    @Test func repositoryURLEndsInTheRepository() {
        #expect(Project.repositoryURL.hasSuffix("/\(Project.repository)"))
    }
}
