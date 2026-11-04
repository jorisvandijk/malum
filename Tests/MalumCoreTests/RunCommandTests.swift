import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct RunCommandTests {
    private let paths = Paths(home: "/Users/joris")
    private let pointer = "/Users/joris/.config/malum/config"
    private let file = "/Users/joris/dots/malum.toml"

    private func run(_ toml: String?, runner: FakeRunner = FakeRunner()) async -> (Bool, [Message]) {
        var texts = [pointer: "/Users/joris/dots\n"]
        texts[file] = toml
        let files = FakeFileSystem(items: ["/opt/homebrew/bin/brew": .file], texts: texts)
        var messages: [Message] = []
        let succeeded = await RunCommand(files: files, paths: paths, runner: runner).run { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func switchedOnInstallsPackages() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(
            "[system_config]\nenabled = true\nformulae = [\"bat\"]\n", runner: runner)
        #expect(succeeded)
        #expect(runner.commands.last?.arguments == ["install", "--formula", "bat"])
        #expect(messages.last == Message(.info, "system_config is done"))
    }

    @Test func switchedOffRunsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run("[system_config]\nformulae = [\"bat\"]\n", runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't run system_config: it's off, set enabled = true in its table in \(file)")
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func badTableRunsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run("[system_config]\nenabled = true\nformulae = \"bat\"\n", runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't run system_config: fix its table in \(file) first"))
        #expect(
            messages.contains(Message(.error, "malum.toml line 3: system_config.formulae should be a list of text")))
        #expect(runner.commands.isEmpty)
    }

    @Test func missingFileIsReported() async {
        let (succeeded, messages) = await run(nil)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't load \(file): it doesn't exist")])
    }

    @Test func failedPartEndsWithAnError() async {
        let runner = FakeRunner { command in
            CommandResult(status: command.arguments.first == "install" ? 1 : 0, errors: "Error: nope\n")
        }
        let (succeeded, messages) = await run(
            "[system_config]\nenabled = true\ncasks = [\"kitty\"]\n", runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "system_config finished with errors"))
    }
}
