import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PackageListTests {
    @Test func homebrewEntriesAreSortedByKind() {
        let reading = PackageList.read(
            """
            [homebrew]
            mole = "formula"
            bitwarden = "cask"
            "olets/tap/zsh-abbr" = "formula"
            """)
        #expect(
            reading.list == PackageList(homebrew: [.formula: ["mole", "olets/tap/zsh-abbr"], .cask: ["bitwarden"]]))
        #expect(reading.problems.isEmpty)
    }

    @Test func emptyFileListsNothing() {
        let reading = PackageList.read("")
        #expect(reading.list == PackageList())
        #expect(reading.problems.isEmpty)
    }

    @Test func wrongKindIsAnErrorWithItsLine() {
        let reading = PackageList.read("[homebrew]\nmole = \"formula\"\nkitty = \"app\"\nbat = 3\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "packages.toml line 3: homebrew.kitty should be \"formula\" or \"cask\""),
                Message(.error, "packages.toml line 4: homebrew.bat should be \"formula\" or \"cask\""),
            ])
    }

    @Test func homebrewThatIsntATableIsAnError() {
        let reading = PackageList.read("homebrew = \"bat\"\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [Message(.error, "packages.toml line 1: homebrew should be a table")])
    }

    @Test func unknownTableIsOnlyAWarning() {
        let reading = PackageList.read("[homebrew]\nbat = \"formula\"\n\n[app_store]\nxcode = 497799835\n")
        #expect(reading.list == PackageList(homebrew: [.formula: ["bat"]]))
        #expect(reading.problems.map(\.message) == [Message(.warn, "packages.toml line 4: unknown table app_store")])
    }

    @Test func syntaxErrorGivesLineAndColumn() {
        let reading = PackageList.read("[homebrew]\nbat = \n")
        #expect(reading.list == nil)
        #expect(reading.problems.first?.line == 2)
        #expect(reading.problems.first?.file == "packages.toml")
    }
}
