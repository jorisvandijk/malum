import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TOMLLinesTests {
    @Test func tablesAndKeysHaveTheirLines() {
        let lines = TOMLLines("# comment\ntop = 1\n\n[window_manager]\ngap = 4\n  floating = []\n")
        #expect(lines.line(of: ["top"]) == 2)
        #expect(lines.line(of: ["window_manager"]) == 4)
        #expect(lines.line(of: ["window_manager", "gap"]) == 5)
        #expect(lines.line(of: ["window_manager", "floating"]) == 6)
    }

    @Test func unknownKeyFallsBackToItsTable() {
        let lines = TOMLLines("[launcher]\nsize = { width = 1 }\n")
        #expect(lines.line(of: ["launcher", "size", "width"]) == 2)
        #expect(lines.line(of: ["launcher", "missing"]) == 1)
        #expect(lines.line(of: ["missing"]) == nil)
    }

    @Test func dottedAndQuotedKeysAreSplit() {
        let lines = TOMLLines("launcher.size = 3\n[\"window manager\" . inner]\n'gap' = 1\n")
        #expect(lines.line(of: ["launcher", "size"]) == 1)
        #expect(lines.line(of: ["window manager", "inner"]) == 2)
        #expect(lines.line(of: ["window manager", "inner", "gap"]) == 3)
    }

    @Test func linesInsideMultiLineStringsAreSkipped() {
        let lines = TOMLLines("[a]\ntext = \"\"\"\n[b]\nfake = 1\n\"\"\"\nreal = 2\n")
        #expect(lines.line(of: ["b"]) == nil)
        #expect(lines.line(of: ["a", "fake"]) == 1)
        #expect(lines.line(of: ["a", "real"]) == 6)
    }

    @Test func arrayOfTablesKeepsItsFirstLine() {
        let lines = TOMLLines("[[app]]\nname = \"a\"\n[[app]]\nname = \"b\"\n")
        #expect(lines.line(of: ["app"]) == 1)
        #expect(lines.line(of: ["app", "name"]) == 2)
    }

    @Test func multiLineArrayItemsAreNotKeys() {
        let lines = TOMLLines("[a]\nlist = [\n  \"x = y\",\n]\nnext = 1\n")
        #expect(lines.line(of: ["a", "\"x"]) == 1)
        #expect(lines.line(of: ["a", "next"]) == 5)
    }
}
