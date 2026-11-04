import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigTests {
    private let path = "/dots/malum.toml"

    private func config() -> Config {
        Config(schemas: [
            "window_manager": ConfigSchema(
                about: "Tiles windows.", settings: ["gap": Setting(.integer, "Space between windows.")]),
            "launcher": ConfigSchema(about: "Opens apps.", settings: ["size": Setting(.integer, "How big it is.")]),
        ])
    }

    @Test func goodFileGivesEveryModuleItsSettings() {
        var config = config()
        let report = config.load("[window_manager]\ngap = 4\n", from: path)
        #expect(report == ConfigReport(loaded: path, changed: ["window_manager", "launcher"], kept: [], problems: []))
        #expect(config.settings == ["window_manager": ["gap": .integer(4)], "launcher": [:]])
    }

    @Test func badTableKeepsOnlyThatModulesLastGoodSettings() {
        var config = config()
        _ = config.load("[window_manager]\ngap = 4\n[launcher]\nsize = 1\n", from: path)
        let report = config.load("[window_manager]\ngap = \"wide\"\n[launcher]\nsize = 2\n", from: path)
        #expect(report.changed == ["launcher"])
        #expect(report.kept == ["window_manager"])
        #expect(report.problems == [ConfigProblem(.error, line: 2, "window_manager.gap should be a whole number")])
        #expect(config.settings == ["window_manager": ["gap": .integer(4)], "launcher": ["size": .integer(2)]])
    }

    @Test func everyProblemIsReportedWithItsLine() {
        var config = config()
        let text = "stray = 1\n[window_manager]\ngap = 1.5\ncolour = 1\n[samba]\n[launcher]\nsize = true\n"
        let report = config.load(text, from: path)
        #expect(report.problems.map(\.line) == [1, 3, 4, 5, 7])
        #expect(report.problems.map(\.message.description).contains("[warn] malum.toml line 5: unknown module samba"))
        #expect(
            report.problems.map(\.message.description).contains(
                "[warn] malum.toml line 1: stray isn't inside a module's table"))
        #expect(report.kept == ["window_manager", "launcher"])
    }

    @Test func moduleThatIsntATableIsAProblem() {
        var config = config()
        let report = config.load("launcher = 3\n", from: path)
        #expect(report.problems == [ConfigProblem(.error, line: 1, "launcher should be a table")])
        #expect(report.kept == ["launcher"])
    }

    @Test func syntaxErrorKeepsEverySetting() {
        var config = config()
        _ = config.load("[launcher]\nsize = 1\n", from: path)
        let report = config.load("[launcher]\nsize = \n", from: path)
        #expect(report.loaded == nil)
        #expect(report.kept == ["window_manager", "launcher"])
        #expect(report.problems.first?.line == 2)
        #expect(config.settings["launcher"] == ["size": .integer(1)])
    }

    @Test func unchangedTableIsNotReportedAsChanged() {
        var config = config()
        _ = config.load("[launcher]\nsize = 1\n", from: path)
        let report = config.load("# a comment\n[launcher]\nsize = 1\n", from: path)
        #expect(report.changed.isEmpty)
    }

    @Test func enabledSwitchesAModuleOn() {
        var config = config()
        let report = config.load("[window_manager]\nenabled = true\ngap = 4\n[launcher]\nenabled = false\n", from: path)
        #expect(report.problems.isEmpty)
        #expect(config.enabled == ["window_manager"])
        #expect(config.settings == ["window_manager": ["gap": .integer(4)], "launcher": [:]])
    }

    @Test func moduleIsOffWithoutEnabled() {
        var config = config()
        _ = config.load("[window_manager]\nenabled = true\n", from: path)
        let report = config.load("[window_manager]\n", from: path)
        #expect(config.enabled.isEmpty)
        #expect(report.changed.isEmpty)
    }

    @Test func enabledThatIsntTrueOrFalseKeepsTheLastSwitch() {
        var config = config()
        _ = config.load("[launcher]\nenabled = true\n", from: path)
        let report = config.load("[launcher]\nenabled = \"yes\"\n", from: path)
        #expect(report.problems == [ConfigProblem(.error, line: 2, "launcher.enabled should be true or false")])
        #expect(report.kept == ["launcher"])
        #expect(config.enabled == ["launcher"])
    }
}
