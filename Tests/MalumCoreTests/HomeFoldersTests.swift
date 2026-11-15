import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct HomeFoldersTests {
    private let paths = Paths(home: "/Users/test")

    /// A home folder with these folders, those in `hidden` hidden, and a file and a dot folder.
    private func home(_ folders: [String], hidden: Set<String> = []) -> FakeFileSystem {
        var items: [String: FileItem] = ["/Users/test/.ssh": .directory]
        for folder in folders { items["/Users/test/\(folder)"] = .directory }
        return FakeFileSystem(
            items: items, texts: ["/Users/test/notes.txt": ""],
            hidden: Set(hidden.map { "/Users/test/\($0)" } + ["/Users/test/.ssh"]))
    }

    @Test func unlistedFoldersAreHiddenAndListedOnesShown() async {
        let runner = FakeRunner()
        let files = home(["Documents", "git", "Movies", "Music", "Library"], hidden: ["git", "Library"])
        var messages: [Message] = []
        let succeeded = await HomeFolders(runner: runner, files: files, paths: paths).set(
            ["Documents", "Git"]) { messages.append($0) }
        #expect(succeeded)
        #expect(
            runner.commands
                == [
                    Chflags.hide("/Users/test/Movies"), Chflags.hide("/Users/test/Music"),
                    Chflags.show("/Users/test/git"),
                ].sorted { $0.arguments[1] < $1.arguments[1] })
        #expect(messages.contains(Message(.info, "hid ~/Movies in Finder, from macos.toml")))
        #expect(messages.contains(Message(.info, "showed ~/git in Finder, from macos.toml")))
    }

    @Test func noTableLeavesEveryFolder() async {
        let runner = FakeRunner()
        let succeeded = await HomeFolders(runner: runner, files: home(["Movies"]), paths: paths).set(nil) { _ in }
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
    }

    @Test func failedChangeIsAWarning() async {
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "chflags: Operation not permitted") }
        var messages: [Message] = []
        let succeeded = await HomeFolders(runner: runner, files: home(["Movies"]), paths: paths).set([]) {
            messages.append($0)
        }
        #expect(!succeeded)
        #expect(messages == [Message(.warn, "couldn't hide ~/Movies in Finder: chflags: Operation not permitted")])
    }

    @Test func listIsReadFromMacOSToml() throws {
        var reader = try TableReader("[home_folders]\nshow = [\"Documents\", \"Git\"]\n", file: "macos.toml")
        #expect(HomeFolders.read(&reader) == ["Documents", "Git"])
        var missing = try TableReader("", file: "macos.toml")
        #expect(HomeFolders.read(&missing) == nil)
        var wrong = try TableReader("[home_folders]\nshow = [\"a/b\"]\n", file: "macos.toml")
        #expect(HomeFolders.read(&wrong) == [])
        #expect(wrong.hasErrors)
    }
}
