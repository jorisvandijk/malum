import Testing

@testable import MalumCore

/// The apps whose preferences system config sets.
extension AppConfigsTests {
    @Test func preferencesAreReadForTheAppsDomain() throws {
        let config = try #require(AppConfigs.app(named: "cursorcerer"))
        var reader = try TableReader("[preferences]\nidleHide = 5\nwhen = 2026-11-05\n", file: "apps/cursorcerer.toml")
        let read = config.read(&reader)
        #expect(read.files.isEmpty)
        #expect(read.preferences.map(\.key) == ["idleHide"])
        #expect(read.preferences.first?.domain == "com.doomlaser.cursorcerer")
        #expect(
            reader.problems.map { Message($0.level, $0.text) } == [
                Message(.error, "preferences.when should be text, a number, true or false, or a list or table of them")
            ])
    }
}
