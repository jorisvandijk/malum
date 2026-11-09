import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct IssueListTests {
    private let failed = Message(.error, "couldn't install Homebrew cask lulu: gone")
    private let unknown = Message(.warn, "kitty.toml line 4: unknown setting fontsize")
    private let wrote = Message(.info, "wrote ~/.gitconfig")

    private func messages(_ reported: [Message]) -> [String] {
        var shown: [String] = []
        let issues = IssueList { shown.append($0.description) }
        reported.forEach(issues.add)
        issues.finish()
        return shown
    }

    @Test func issuesAreNumberedAsTheyHappenAndListedAtTheEnd() {
        #expect(
            messages([failed, wrote, unknown]) == [
                "[error] #1 couldn't install Homebrew cask lulu: gone",
                "[info] wrote ~/.gitconfig",
                "[warn] #2 kitty.toml line 4: unknown setting fontsize",
                "[error] 2 issues in this run:",
                "[error] #1 couldn't install Homebrew cask lulu: gone",
                "[warn] #2 kitty.toml line 4: unknown setting fontsize",
            ])
    }

    @Test func noIssuesAddsNothing() {
        #expect(messages([wrote]) == ["[info] wrote ~/.gitconfig"])
    }

    @Test func onlyWarningsMakeAWarningHeading() {
        #expect(messages([unknown]).dropLast().last == "[warn] 1 issue in this run:")
    }

    @Test func numberKeepsPrivatePartsPrivate() {
        let message = Message.issue(3, Message(.error, "couldn't read \(private: "/a")"))
        #expect(message.text.redacted == "#3 couldn't read <private>")
    }
}
