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

    @Test func valuesAreWrittenAsTOML() {
        #expect(ConfigValue.string("Finder").toml == "\"Finder\"")
        #expect(ConfigValue.integer(-3).toml == "-3")
        #expect(ConfigValue.float(0.5).toml == "0.5")
        #expect(ConfigValue.boolean(true).toml == "true")
        #expect(ConfigValue.date("2026-11-03").toml == "2026-11-03")
        #expect(ConfigValue.array([.string("a"), .integer(1)]).toml == "[\"a\", 1]")
        #expect(ConfigValue.table([:]).toml == "{}")
        #expect(ConfigValue.table(["b": .integer(2), "a b": .integer(1)]).toml == "{ \"a b\" = 1, b = 2 }")
    }

    @Test func specialCharactersAreEscaped() {
        #expect(ConfigValue.string("a\"b\\c\nd\te\u{1}").toml == "\"a\\\"b\\\\c\\nd\\te\\u0001\"")
    }

    @Test func writtenValueReadsBackTheSame() throws {
        let value = ConfigValue.table([
            "text": .string("quote \" slash \\ line\n\u{7}"),
            "odd key": .array([.float(1e20), .float(-0.25), .boolean(false)]),
            "inner": .table(["count": .integer(7)]),
        ])
        let table = ConfigValue.table(try TOMLReader.table(from: "value = \(value.toml)"))
        #expect(table["value"] == value)
    }
}
