import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct FileSystemErrorTests {
    @Test func pathIsPrivateAndReasonIsNot() {
        let error = FileSystemError.unreadable(path: "/Users/joris/git/dots/malum.toml", reason: "no such file")
        #expect(error.description == "couldn't read /Users/joris/git/dots/malum.toml: no such file")
        #expect(error.text.redacted == "couldn't read <private>: no such file")
    }
}
