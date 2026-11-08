import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigSchemaTests {
    private let schema = ConfigSchema(
        about: "Tiles windows.",
        settings: [
            "gap": Setting(.integer, "Space between windows."), "floating": Setting(.strings, "Apps left alone."),
        ])

    @Test func goodTableHasNoProblems() {
        let table: ConfigTable = ["gap": .integer(4), "floating": .array([.string("Finder")])]
        #expect(schema.problems(in: table, at: ["window_manager"]).isEmpty)
    }

    @Test func missingSettingsAreFine() {
        #expect(schema.problems(in: [:], at: ["window_manager"]).isEmpty)
    }

    @Test func everyProblemIsListed() {
        let table: ConfigTable = ["gap": .string("4"), "colour": .string("red")]
        #expect(
            schema.problems(in: table, at: ["window_manager"]) == [
                "gap": "window_manager.gap should be a whole number",
                "colour": "unknown setting window_manager.colour",
            ])
    }

    @Test func everyModuleTakesEnabled() {
        #expect(
            schema.settings["enabled"] == Setting(.boolean, ConfigSchema.switchSetting.about, default: .boolean(false)))
        #expect(schema.problems(in: ["enabled": .boolean(true)], at: ["window_manager"]).isEmpty)
    }

    @Test func moduleCantReplaceEnabled() {
        let schema = ConfigSchema(about: "Opens apps.", settings: ["enabled": Setting(.string, "Its own.")])
        #expect(schema.settings["enabled"]?.kind == .boolean)
    }
}
