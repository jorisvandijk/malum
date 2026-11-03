import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct InitCommandTests {
    let paths = Paths(home: "/Users/joris")
    let dots = "/Users/joris/git/dots"
    let executable = "/Users/joris/Applications/Malum.app/Contents/MacOS/Malum"

    func run(_ files: FakeFileSystem, dots argument: String = "~/git/dots") -> [Message] {
        InitCommand(files: files, paths: paths).run(
            dots: argument, workingDirectory: "/Users/joris", executable: executable)
    }

    @Test func firstInitRecordsDotsAndLinks() {
        let files = FakeFileSystem(items: [dots: .directory])
        #expect(
            run(files) == [
                Message(.info, "dots is at \(dots), saved in \(paths.configFile)"),
                Message(.info, "linked \(paths.commandLink) to \(executable)"),
            ])
        #expect(files.text(at: paths.configFile) == dots + "\n")
        #expect(files.item(at: paths.commandLink) == .link(to: executable))
    }

    @Test func relativeDotsIsReadFromWorkingDirectory() {
        let files = FakeFileSystem(items: [dots: .directory])
        _ = run(files, dots: "git/dots")
        #expect(files.text(at: paths.configFile) == dots + "\n")
    }

    @Test func secondInitChangesNothing() {
        let files = FakeFileSystem(
            items: [dots: .directory, paths.commandLink: .link(to: executable)],
            texts: [paths.configFile: dots + "\n"])
        #expect(
            run(files) == [
                Message(.info, "dots is already at \(dots)"),
                Message(.info, "\(paths.commandLink) already points to \(executable)"),
            ])
    }

    @Test func movedDotsIsRecorded() {
        let files = FakeFileSystem(items: [dots: .directory], texts: [paths.configFile: "/old/dots\n"])
        #expect(run(files).first == Message(.info, "dots moved from /old/dots to \(dots)"))
        #expect(files.text(at: paths.configFile) == dots + "\n")
    }

    @Test func missingDotsIsAnErrorButStillLinks() {
        let files = FakeFileSystem()
        #expect(
            run(files) == [
                Message(.error, "couldn't use \(dots) as dots: folder not found"),
                Message(.info, "linked \(paths.commandLink) to \(executable)"),
            ])
        #expect(files.item(at: paths.configFile) == nil)
    }

    @Test func runningOutsideTheAppWarns() {
        let files = FakeFileSystem(items: [dots: .directory])
        let messages = InitCommand(files: files, paths: paths)
            .run(dots: dots, workingDirectory: "/", executable: nil)
        #expect(messages.last == Message(.warn, SetupError.notInApp(path: paths.commandLink).description))
        #expect(files.item(at: paths.commandLink) == nil)
    }

    @Test func failedWriteIsAnError() {
        let files = FakeFileSystem(items: [dots: .directory], failing: [paths.configFile])
        #expect(run(files).first == Message(.error, "couldn't write \(paths.configFile): read-only"))
    }
}
