import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigModuleFileTests {
    private let path = "/dots/malum.toml"
    private let file = "/dots/launcher.toml"

    private func config() -> Config {
        Config(schemas: [
            "launcher": ConfigSchema(about: "Opens apps.", settings: ["size": Setting(.integer, "How big it is.")])
        ])
    }

    private func load(_ config: inout Config, _ text: String, launcher: String) -> ConfigReport {
        config.load(text, from: path, moduleFiles: ["launcher": .text(path: file, launcher)])
    }

    @Test func settingsComeFromTheModulesFileAndTheSwitchFromConfig() {
        var config = config()
        let report = load(&config, "[launcher]\nenabled = true\n", launcher: "size = 3\n")
        #expect(
            report == ConfigReport(loaded: path, moduleFiles: [file], changed: ["launcher"], kept: [], problems: []))
        #expect(config.settings == ["launcher": ["size": .integer(3)]])
        #expect(config.enabled == ["launcher"])
    }

    @Test func moduleWithOnlyItsFileIsOff() {
        var config = config()
        _ = load(&config, "", launcher: "size = 3\n")
        #expect(config.settings == ["launcher": ["size": .integer(3)]])
        #expect(config.enabled.isEmpty)
    }

    @Test func settingsInBothPlacesKeepTheLastGoodOnes() {
        var config = config()
        _ = load(&config, "[launcher]\n", launcher: "size = 3\n")
        let report = load(&config, "# both\n[launcher]\nsize = 4\n", launcher: "size = 5\n")
        #expect(
            report.problems == [
                ConfigProblem(
                    .error, line: 2, "launcher has settings here and in launcher.toml: keep them in one of the two")
            ])
        #expect(report.kept == ["launcher"])
        #expect(report.moduleFiles.isEmpty)
        #expect(config.settings == ["launcher": ["size": .integer(3)]])
    }

    @Test func switchInTheModulesFileIsAProblem() {
        var config = config()
        let report = load(&config, "", launcher: "size = 3\nenabled = true\n")
        #expect(
            report.problems == [
                ConfigProblem(
                    .error, file: "launcher.toml", line: 2,
                    "enabled goes in the [launcher] table of malum.toml, not here")
            ])
        #expect(report.kept == ["launcher"])
        #expect(config.enabled.isEmpty)
    }

    @Test func everyProblemInTheModulesFileIsReportedAtItsLine() {
        var config = config()
        let report = load(&config, "", launcher: "# launcher\nsize = \"big\"\ncolour = 1\n")
        #expect(
            report.messages.map(\.description) == [
                "[info] loaded /dots/malum.toml",
                "[error] launcher.toml line 2: size should be a whole number",
                "[error] launcher.toml line 3: unknown setting colour",
                "[warn] launcher keeps its last good settings",
            ])
    }

    @Test func syntaxErrorInTheModulesFileKeepsOnlyThatModule() {
        var config = config()
        let report = load(&config, "", launcher: "size = \n")
        #expect(report.loaded == path)
        #expect(report.kept == ["launcher"])
        #expect(report.problems.first?.file == "launcher.toml")
        #expect(report.problems.first?.line == 1)
    }

    @Test func unreadableModuleFileKeepsTheLastGoodSettings() {
        var config = config()
        _ = load(&config, "", launcher: "size = 3\n")
        let error = FileSystemError.unreadable(path: file, reason: "no such file")
        let report = config.load("", from: path, moduleFiles: ["launcher": .unreadable(path: file, error)])
        #expect(report.problems == [ConfigProblem(.error, file: "launcher.toml", error.text)])
        #expect(report.kept == ["launcher"])
        #expect(config.settings == ["launcher": ["size": .integer(3)]])
    }

    @Test func removedModuleFileDropsItsSettings() {
        var config = config()
        _ = load(&config, "", launcher: "size = 3\n")
        let report = config.load("", from: path)
        #expect(report.changed == ["launcher"])
        #expect(config.settings == ["launcher": [:]])
    }
}
