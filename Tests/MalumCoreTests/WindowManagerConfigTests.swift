import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct WindowManagerConfigTests {
    private let path = "/dots/malum.toml"
    private let file = "/dots/window_manager.toml"
    private let fileName = "window_manager.toml"
    private let module = WindowManagerConfig.module

    /// The settings `text`, as `window_manager.toml`, give, read the way the module does.
    private func load(_ text: String) -> (config: WindowManagerConfig?, problems: [ConfigProblem]) {
        var config = Config(schemas: [module: WindowManagerConfig.schema])
        let report = config.load("", from: path, moduleFiles: [module: .text(path: file, text)])
        let table = config.moduleSettings[module]?.table
        return (table.map { WindowManagerConfig.read($0) { _, _ in } }, report.problems)
    }

    @Test func nothingSetGivesTheDefaults() {
        let (config, problems) = load("")
        #expect(problems.isEmpty)
        #expect(config == WindowManagerConfig())
        #expect(config?.frame == .visible)
        #expect(config?.blocksHideMinimize == true)
    }

    @Test func everySettingIsRead() {
        let text = """
            frame = "full"
            block_hide_minimize = false

            [[float]]
            app = "com.apple.systempreferences"

            [[float]]
            app = "org.mozilla.librewolf"
            title = "^Picture-in-Picture$"
            """
        let (config, problems) = load(text)
        #expect(problems.isEmpty)
        #expect(
            config
                == WindowManagerConfig(
                    frame: .full, blocksHideMinimize: false,
                    floats: [
                        FloatRule(app: "com.apple.systempreferences", title: nil),
                        FloatRule(app: "org.mozilla.librewolf", title: "^Picture-in-Picture$"),
                    ]))
    }

    @Test func settingsCanBeInConfig() {
        var config = Config(schemas: [module: WindowManagerConfig.schema])
        let text = "[window_manager]\nframe = \"full\"\n\n[[window_manager.float]]\napp = \"com.apple.finder\"\n"
        let report = config.load(text, from: path)
        #expect(report.problems.isEmpty)
        let table = config.moduleSettings[module]?.table ?? [:]
        let read = WindowManagerConfig.read(table) { _, _ in }
        #expect(read == WindowManagerConfig(frame: .full, floats: [FloatRule(app: "com.apple.finder", title: nil)]))
    }

    @Test func unknownFrameIsAnErrorAtItsLine() {
        let (config, problems) = load("frame = \"half\"\n")
        #expect(config == nil)
        #expect(
            problems == [ConfigProblem(.error, file: fileName, line: 1, .shouldBe("frame", MessageText.screenFrame))])
    }

    @Test func badFloatRulesAreErrorsAtTheirOwnLines() {
        let text = """
            [[float]]
            app = "com.apple.finder"

            [[float]]
            app = ""

            [[float]]
            app = "org.mozilla.librewolf"
            title = "(unclosed"
            size = 3
            """
        let (config, problems) = load(text)
        #expect(config == nil)
        #expect(
            problems == [
                ConfigProblem(.error, file: fileName, line: 5, .notBundleID("float.1.app")),
                ConfigProblem(.error, file: fileName, line: 9, .shouldBe("float.2.title", MessageText.titlePattern)),
                ConfigProblem(.error, file: fileName, line: 10, .unknownKey("float.2.size", isTable: false)),
            ])
    }

    @Test func problemInConfigNamesTheWholePath() {
        var config = Config(schemas: [module: WindowManagerConfig.schema])
        let report = config.load("[window_manager]\nframe = \"half\"\n", from: path)
        #expect(
            report.problems == [
                ConfigProblem(.error, line: 2, .shouldBe("window_manager.frame", MessageText.screenFrame))
            ])
    }

    @Test func floatThatIsNotAListOfTablesIsAnError() {
        let (config, problems) = load("float = [\"com.apple.finder\"]\n")
        #expect(config == nil)
        #expect(problems == [ConfigProblem(.error, file: fileName, line: 1, .shouldBe("float", SettingKind.tables))])
    }
}
