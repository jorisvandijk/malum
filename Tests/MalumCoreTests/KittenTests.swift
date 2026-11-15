import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KittenTests {
    @Test func newTabTalksToTheRunningKittysSocket() {
        let socket = Kitten.socket(processID: 42)
        #expect(socket == "/tmp/kitty-42")
        let command = Kitten.newTab(app: "/Applications/kitty.app", socket: socket, program: ["/bin/zsh", "-l"])
        #expect(command.executable == "/Applications/kitty.app/Contents/MacOS/kitten")
        #expect(
            command.arguments == ["@", "--to", "unix:/tmp/kitty-42", "launch", "--type=tab", "/bin/zsh", "-l"])
    }
}
