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
            [windows]
            frame = "full"
            allow_hide_minimize = true
            split_step_percent = 10

            [floating_windows.settings]
            app = "com.apple.systempreferences"

            [floating_windows.picture_in_picture]
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
                        FloatRule(app: "org.mozilla.librewolf", title: "^Picture-in-Picture$"),
                        FloatRule(app: "com.apple.systempreferences", title: nil),
                    ], splitStep: 10))
    }

    @Test func settingsInConfigAreErrors() {
        var config = Config(schemas: [module: WindowManagerConfig.schema])
        let report = config.load("[window_manager]\nenabled = true\nframe = \"full\"\n", from: path)
        #expect(
            report.problems == [ConfigProblem(.error, line: 3, .unknownKey("window_manager.frame", isTable: false))])
    }

    @Test func wrongValuesAreErrorsAtTheirLines() {
        let (config, problems) = load("[windows]\nframe = \"half\"\nsplit_step_percent = 30\n")
        #expect(config == nil)
        #expect(
            problems.map(\.message) == [
                Message(.error, "window_manager.toml line 2: windows.frame should be \"visible\" or \"full\""),
                Message(
                    .error,
                    "window_manager.toml line 3: windows.split_step_percent should be a whole number from 1 to 25"),
            ])
    }

    @Test func badFloatingWindowsAreErrorsAtTheirOwnLines() {
        let text = """
            [floating_windows.finder]
            app = "com.apple.finder"

            [floating_windows.empty]
            app = ""

            [floating_windows.librewolf]
            app = "org.mozilla.librewolf"
            title = "(unclosed"
            size = 3

            [floating_windows.nothing]
            title = "^A$"
            """
        let (config, problems) = load(text)
        #expect(config == nil)
        #expect(
            problems == [
                ConfigProblem(
                    .error, file: fileName, line: 5,
                    .shouldBe("floating_windows.empty.app", CatalogValue.app(before: "", after: ""))),
                ConfigProblem(
                    .error, file: fileName, line: 9,
                    .shouldBe("floating_windows.librewolf.title", MessageText.titlePattern)),
                ConfigProblem(
                    .warn, file: fileName, line: 10, .unknownKey("floating_windows.librewolf.size", isTable: false)),
                ConfigProblem(.error, file: fileName, line: 12, .needs("floating_windows.nothing", "app")),
            ])
    }

    @Test func oldLayoutIsUnknown() {
        let (_, problems) = load("[settings]\nframe = \"full\"\n\n[[float]]\napp = \"com.apple.finder\"\n")
        #expect(
            problems == [
                ConfigProblem(.warn, file: fileName, line: 1, .unknownKey("settings", isTable: true)),
                ConfigProblem(.warn, file: fileName, line: 4, .unknownKey("float", isTable: false)),
            ])
    }

    @Test func splitStepDefaultsToFive() {
        #expect(load("").config?.splitStep == 5)
        #expect(WindowManagerConfig.read([:]) { _, _ in }.splitStep == 5)
    }
}
