import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ConfigReloaderTests {
    private let paths = Paths(home: "/Users/joris")
    private let pointer = "/Users/joris/.config/malum/config"
    private let file = "/Users/joris/dots/malum.toml"
    private let schemas = ["launcher": ConfigSchema(["size": .integer])]

    @Test func fileIsReadFromDots() {
        let files = FakeFileSystem(texts: [pointer: "/Users/joris/dots\n", file: "[launcher]\nsize = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(reloader.reload(force: false)?.messages == [Message(.info, "loaded \(file)")])
        #expect(reloader.settings == ["launcher": ["size": .integer(3)]])
        #expect(reloader.path == file)
    }

    @Test func sameTextIsSkippedUnlessForced() throws {
        let files = FakeFileSystem(texts: [pointer: "/Users/joris/dots\n", file: "[launcher]\nsize = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        _ = reloader.reload(force: false)
        #expect(reloader.reload(force: false) == nil)
        #expect(reloader.reload(force: true)?.loaded == file)
        try files.write("[launcher]\nsize = 4\n", to: file)
        #expect(reloader.reload(force: false)?.changed == ["launcher"])
    }

    @Test func noDotsSaysToRunInit() {
        let reloader = ConfigReloader(files: FakeFileSystem(), paths: paths, schemas: schemas)
        let report = reloader.reload(force: false)
        #expect(
            report?.messages.first == Message(.error, "couldn't load malum.toml: no dots folder yet, run malum init"))
        #expect(report?.kept == ["launcher"])
        #expect(reloader.path == nil)
    }

    @Test func missingFileIsReportedOnceUntilForced() {
        let files = FakeFileSystem(texts: [pointer: "/Users/joris/dots\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(
            reloader.reload(force: false)?.problems == [
                ConfigProblem(.error, "couldn't load \(file): it doesn't exist")
            ])
        #expect(reloader.reload(force: false) == nil)
        #expect(reloader.reload(force: true) != nil)
        #expect(reloader.path == file)
    }

    @Test func badTableKeepsLastGoodSettings() throws {
        let files = FakeFileSystem(texts: [pointer: "/Users/joris/dots\n", file: "[launcher]\nsize = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        _ = reloader.reload(force: false)
        try files.write("[launcher]\nsize = \"big\"\n", to: file)
        let report = reloader.reload(force: false)
        #expect(
            report?.messages == [
                Message(.info, "loaded \(file)"),
                Message(.error, "malum.toml line 2: launcher.size should be a whole number"),
                Message(.warn, "launcher keeps its last good settings"),
            ])
        #expect(reloader.settings == ["launcher": ["size": .integer(3)]])
    }
}
