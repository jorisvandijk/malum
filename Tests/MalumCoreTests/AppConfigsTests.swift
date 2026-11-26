import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppConfigsTests {
    /// The line at the top of each file of `app` that has comments.
    static func header(of app: String) -> String {
        "# Written by Malum from apps/\(app).toml in dots. Changes made here are overwritten.\n"
    }

    /// What `app` makes of its TOML `text`.
    func read(
        _ text: String, app: String
    ) throws -> (files: [AppFile], problems: [Message]) {
        let config = try #require(AppConfigs.app(named: app))
        var reader = try TableReader(text, file: "apps/\(app).toml")
        let files = config.read(&reader, home: "/Users/test").files
        return (files, reader.problems.map { Message($0.level, $0.text) })
    }
}
