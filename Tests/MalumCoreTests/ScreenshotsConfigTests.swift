import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotsConfigTests {
    private let path = "/dots/malum.toml"
    private let file = "/dots/screenshots.toml"
    private let fileName = "screenshots.toml"
    private let module = ScreenshotsConfig.module

    /// The settings `text`, as `screenshots.toml`, give, read the way the module does.
    private func load(_ text: String) -> (config: ScreenshotsConfig?, problems: [ConfigProblem]) {
        var config = Config(schemas: [module: ScreenshotsConfig.schema])
        let report = config.load("", from: path, moduleFiles: [module: .text(path: file, text)])
        let table = config.moduleSettings[module]?.table
        return (table.map { ScreenshotsConfig.read($0) { _, _ in } }, report.problems)
    }

    @Test func nothingSetGivesTheDefaults() {
        let (config, problems) = load("")
        #expect(problems.isEmpty)
        #expect(config == ScreenshotsConfig())
        #expect(config?.colors.count == ScreenshotsConfig.maxColors)
        #expect(config?.colors.first == ScreenshotColor(red: 255, green: 59, blue: 48))
    }

    @Test func folderAndColorsAreRead() {
        let (config, problems) = load("folder = \"~/Pictures/Shots\"\ncolors = [\"#00FF00\", \"#123abc\"]\n")
        #expect(problems.isEmpty)
        #expect(config?.folder == "~/Pictures/Shots")
        #expect(
            config?.colors == [
                ScreenshotColor(red: 0, green: 255, blue: 0), ScreenshotColor(red: 18, green: 58, blue: 188),
            ])
    }

    @Test func settingsCanBeInConfig() {
        var config = Config(schemas: [module: ScreenshotsConfig.schema])
        let report = config.load("[screenshots]\nfolder = \"/tmp/shots\"\n", from: path)
        #expect(report.problems.isEmpty)
        let read = ScreenshotsConfig.read(config.moduleSettings[module]?.table ?? [:]) { _, _ in }
        #expect(read.folder == "/tmp/shots")
    }

    @Test func folderPathExpandsHome() {
        let paths = Paths(home: "/Users/test")
        #expect(ScreenshotsConfig().folderPath(paths) == "/Users/test/Documents")
        #expect(ScreenshotsConfig(folder: "Shots").folderPath(paths) == "/Users/test/Shots")
        #expect(ScreenshotsConfig(folder: "/Volumes/data/shots").folderPath(paths) == "/Volumes/data/shots")
    }

    @Test func eachProblemIsAtItsLineAndTheModuleGetsNoSettings() {
        let (config, problems) = load("folder = \"\"\ncolors = [\"red\"]\nsize = 3\n")
        #expect(config == nil)
        #expect(
            problems == [
                ConfigProblem(.error, file: fileName, line: 1, .shouldBe("folder", MessageText.screenshotFolder)),
                ConfigProblem(.error, file: fileName, line: 2, .shouldBe("colors", MessageText.screenshotColors)),
                ConfigProblem(.error, file: fileName, line: 3, .unknownKey("size", isTable: false)),
            ])
    }

    @Test func colorsNeedOneToSeven() {
        let eight = Array(repeating: "\"#000000\"", count: ScreenshotsConfig.maxColors + 1).joined(separator: ", ")
        for list in ["[]", "[\(eight)]"] {
            let (config, problems) = load("colors = \(list)\n")
            #expect(config == nil)
            #expect(problems.map(\.text) == [.shouldBe("colors", MessageText.screenshotColors)])
        }
    }

    @Test func wrongKindsAreReported() {
        let (_, problems) = load("folder = 1\ncolors = \"#ff0000\"\n")
        #expect(
            problems.map(\.text) == [
                .shouldBe("folder", SettingKind.string), .shouldBe("colors", SettingKind.strings),
            ])
    }
}
