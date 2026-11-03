import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigValueTests {
    @Test func everyKindIsCopied() throws {
        let text = """
            name = "a"
            count = 3
            ratio = 0.5
            on = true
            day = 2026-11-03
            list = ["x", 1]
            [inner]
            key = "b"
            """
        let table = ConfigValue.table(try TOMLReader.table(from: text))
        #expect(table["name"] == .string("a"))
        #expect(table["count"] == .integer(3))
        #expect(table["ratio"] == .float(0.5))
        #expect(table["on"] == .boolean(true))
        #expect(table["day"] == .date("2026-11-03"))
        #expect(table["list"] == .array([.string("x"), .integer(1)]))
        #expect(table["inner"] == .table(["key": .string("b")]))
    }

    @Test func sameTextGivesEqualTables() throws {
        let text = "[window_manager]\ngap = 4\nfloating = [\"a\"]\n"
        let first = ConfigValue.table(try TOMLReader.table(from: text))
        let second = ConfigValue.table(try TOMLReader.table(from: text))
        #expect(first == second)
    }
}
