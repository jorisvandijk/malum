import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LaunchCountsTests {
    private let paths = Paths(home: "/Users/test")
    private var file: String { "\(paths.stateDirectory)/launches.json" }

    private func counts(_ text: String? = nil) -> (LaunchCounts, FakeFileSystem) {
        let files = FakeFileSystem(texts: text.map { [file: $0] } ?? [:])
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return (LaunchCounts(state: state), files)
    }

    @Test func nothingStartedYetIsEmpty() throws {
        #expect(try counts().0.read().isEmpty)
    }

    @Test func recordAddsOne() throws {
        let (counts, files) = counts("{\"com.apple.mail\":2}")
        try counts.record("com.apple.mail")
        try counts.record("net.kovidgoyal.kitty")
        #expect(try counts.read() == ["com.apple.mail": 3, "net.kovidgoyal.kitty": 1])
        #expect(try files.read(file) == "{\"com.apple.mail\":3,\"net.kovidgoyal.kitty\":1}")
    }

    @Test func damagedFileStartsOver() throws {
        let (counts, _) = counts("not json")
        #expect(try counts.read().isEmpty)
        try counts.record("a")
        #expect(try counts.read() == ["a": 1])
    }
}
