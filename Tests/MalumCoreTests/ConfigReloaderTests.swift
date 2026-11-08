import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ConfigReloaderTests {
    private let paths = Paths(home: "/Users/test")
    private let pointer = "/Users/test/.config/malum/config"
    private let file = "/Users/test/dots/malum.toml"
    private let schemas = [
        "launcher": ConfigSchema(about: "Opens apps.", settings: ["size": Setting(.integer, "How big it is.")])
    ]

    @Test func fileIsReadFromDots() {
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n", file: "[launcher]\nsize = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(reloader.reload(force: false)?.messages == [Message(.info, "loaded \(file)")])
        #expect(reloader.settings == ["launcher": ["size": .integer(3)]])
        #expect(reloader.path == file)
    }

    @Test func sameTextIsSkippedUnlessForced() throws {
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n", file: "[launcher]\nsize = 3\n"])
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
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n"])
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
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n", file: "[launcher]\nsize = 3\n"])
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

    @Test func modulesOwnFileIsReadAndWatched() throws {
        let launcher = "/Users/test/dots/launcher.toml"
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n", file: "[launcher]\n", launcher: "size = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(
            reloader.reload(force: false)?.messages == [
                Message(.info, "loaded \(file)"), Message(.info, "loaded \(launcher)"),
            ])
        #expect(reloader.settings == ["launcher": ["size": .integer(3)]])
        #expect(reloader.watchedFiles == [file, launcher])
        try files.write("size = 4\n", to: launcher)
        #expect(reloader.reload(force: false)?.changed == ["launcher"])
        #expect(reloader.settings == ["launcher": ["size": .integer(4)]])
    }

    @Test func missingModuleFileIsStillWatched() {
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n", file: "[launcher]\nsize = 3\n"])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(reloader.reload(force: false)?.moduleFiles == [])
        #expect(reloader.watchedFiles == [file, "/Users/test/dots/launcher.toml"])
    }

    @Test func unreadableModuleFileIsReported() {
        let launcher = "/Users/test/dots/launcher.toml"
        let files = FakeFileSystem(items: [launcher: .file], texts: [pointer: "/Users/test/dots\n", file: ""])
        let reloader = ConfigReloader(files: files, paths: paths, schemas: schemas)
        #expect(
            reloader.reload(force: false)?.messages.map(\.description) == [
                "[info] loaded \(file)",
                "[error] couldn't read \(launcher): no such file",
                "[warn] launcher keeps its last good settings",
            ])
    }
}
