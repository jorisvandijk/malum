import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ModuleOverviewTests {
    private let paths = Paths(home: "/Users/test")
    private let pointer = "/Users/test/.config/malum/config"
    private let file = "/Users/test/dots/malum.toml"
    private var disabledFile: String { "\(paths.stateDirectory)/disabled" }
    private var safeModeFile: String { "\(paths.stateDirectory)/safe-mode" }

    /// What the overview reports for a disk holding `texts`, with dots pointed at.
    private func overview(_ texts: [String: String]) -> [Message] {
        let files = FakeFileSystem(texts: texts.merging([pointer: "/Users/test/dots\n"]) { own, _ in own })
        var messages: [Message] = []
        ModuleOverview(
            files: files, paths: paths, state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        )
        .report { messages.append($0) }
        return messages
    }

    @Test func eachModuleSaysWhetherItRuns() {
        let messages = overview([
            file: "[launcher]\nenabled = true\n[samba]\nenabled = true\n", disabledFile: "samba\n",
        ])
        #expect(
            messages == [
                Message(.info, "clipboard: off in malum.toml"), Message(.info, "keyboard: off in malum.toml"),
                Message(.info, "launcher: on"),
                Message(.warn, "samba: kept off with malum disable, the menu bar enables it"),
                Message(.info, "screenshots: off in malum.toml"), Message(.info, "window_manager: off in malum.toml"),
            ])
    }

    @Test func safeModeKeepsEveryModuleOff() {
        let messages = overview([file: "[launcher]\nenabled = true\n", safeModeFile: "crash loop\n"])
        #expect(messages.first == Message(.warn, "safe mode is on: Malum started 3 times within 2 minutes"))
        #expect(messages.contains(Message(.warn, "launcher: off in safe mode")))
    }

    @Test func configProblemsAreReported() {
        let messages = overview([file: "[launcher]\nenabled = \"yes\"\n"])
        #expect(messages.first == Message(.error, "malum.toml line 2: launcher.enabled should be true or false"))
        #expect(messages.contains(Message(.info, "launcher: off in malum.toml")))
    }
}
