import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigProblemTests {
    @Test func lineAndColumnComeFirst() {
        let problem = ConfigProblem(.error, line: 3, column: 7, "cannot redefine 'gap'")
        #expect(problem.message == Message(.error, "malum.toml line 3, column 7: cannot redefine 'gap'"))
    }

    @Test func lineAloneComesFirst() {
        let problem = ConfigProblem(.warn, line: 5, "unknown module launcher")
        #expect(problem.message == Message(.warn, "malum.toml line 5: unknown module launcher"))
    }

    @Test func noLineGivesTheTextAlone() {
        let problem = ConfigProblem(.error, "couldn't load /dots/malum.toml: it doesn't exist")
        #expect(problem.message == Message(.error, "couldn't load /dots/malum.toml: it doesn't exist"))
    }

    @Test func byLineSortsProblemsWithoutALineLast() {
        let problems = [
            ConfigProblem(.error, "no line"), ConfigProblem(.warn, line: 9, "nine"),
            ConfigProblem(.warn, line: 2, "two"),
        ]
        #expect(ConfigProblem.byLine(problems).map(\.line) == [2, 9, nil])
    }
}
