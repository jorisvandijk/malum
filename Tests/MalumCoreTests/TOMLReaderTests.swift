import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TOMLReaderTests {
    @Test func validTextGivesTable() throws {
        let table = try TOMLReader.table(from: "[window_manager]\ngap = 4\n")
        #expect(table["window_manager"]?.table?["gap"]?.int == 4)
    }

    @Test func unclosedArrayReportsLineAndColumn() {
        let text = "[window_manager]\nfloating = [\"a\"\n\n[launcher]\n"
        #expect(throws: TOMLReadError.self) { try TOMLReader.table(from: text) }
        #expect(position(of: text) == Position(line: 4, column: 1))
    }

    @Test func duplicateKeyReportsItsLine() {
        let text = "[window_manager]\ngap = 1\ngap = 2\n"
        #expect(position(of: text)?.line == 3)
    }

    @Test func syntaxDescriptionStartsWithPosition() {
        let error = TOMLReadError.syntax(line: 3, column: 7, reason: "cannot redefine 'gap'")
        #expect(error.description == "line 3, column 7: cannot redefine 'gap'")
    }

    private struct Position: Equatable {
        let line: Int
        let column: Int
    }

    private func position(of text: String) -> Position? {
        do {
            _ = try TOMLReader.table(from: text)
            return nil
        } catch {
            guard case .syntax(let line, let column, _) = error else { return nil }
            return Position(line: line, column: column)
        }
    }
}
