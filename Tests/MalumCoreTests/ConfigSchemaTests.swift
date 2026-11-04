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
        #expect(schema.problems(in: table, module: "window_manager").isEmpty)
    }

    @Test func missingSettingsAreFine() {
        #expect(schema.problems(in: [:], module: "window_manager").isEmpty)
    }

    @Test func everyProblemIsListed() {
        let table: ConfigTable = ["gap": .string("4"), "colour": .string("red")]
        #expect(
            schema.problems(in: table, module: "window_manager") == [
                "gap": "window_manager.gap should be a whole number",
                "colour": "unknown setting window_manager.colour",
            ])
    }
}
