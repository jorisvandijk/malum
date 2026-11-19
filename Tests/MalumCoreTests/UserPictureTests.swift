import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct UserPictureTests {
    private static let folder = "/Users/test/dots/pictures"
    private static let source = "\(folder)/me.png"
    private static let named: ConfigTable = [UserPicture.key: .string("me")]
    nonisolated private static let setFailure = "Cannot set the picture"
    private let paths = Paths(home: "/Users/test")

    /// Where Malum keeps the picture made from `data`.
    private func kept(_ data: Data = FakeSquarePictures.square) -> String {
        "\(paths.stateDirectory)/user-picture-\(Fingerprint.of(data)).jpg"
    }

    /// The import file `dsimport` reads.
    private var importFile: String { "\(paths.stateDirectory)/user-picture.import" }

    /// The `dscl -read` answer naming `picture`.
    private static func showing(_ picture: String) -> CommandResult {
        CommandResult(status: 0, output: "Picture:\n \(picture)\n")
    }

    /// Answers reading the picture with `current` and the account's copy with whether `hasPhoto`
    /// is set, and fails setting the picture when `failing` is set.
    private func dscl(
        current: CommandResult = showing("/a.heic"), hasPhoto: Bool = true, failing: Bool = false
    ) -> FakeRunner {
        FakeRunner { command in
            switch command {
            case Dscl.readPicture(of: "test"):
                return current
            case Dscl.readPhoto(of: "test"):
                return CommandResult(status: hasPhoto ? 0 : 1)
            default:
                let refused = failing && command.arguments.contains("-create")
                return refused ? CommandResult(status: 1, errors: Self.setFailure) : CommandResult(status: 0)
            }
        }
    }

    /// Sets the picture with `settings` on `files` through `runner`, and gives back whether it
    /// worked and what it said.
    private func set(
        _ settings: ConfigTable = Self.named, files: FakeFileSystem, runner: FakeRunner,
        pictures: FakeSquarePictures = FakeSquarePictures()
    ) async -> (Bool, [Message]) {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        var messages: [Message] = []
        let succeeded = await UserPicture(
            files: files, paths: paths, runner: runner, sudo: SudoSession(runner: runner, canAsk: true),
            state: state, pictures: pictures, user: "test"
        ).set(settings, dots: "/Users/test/dots") { messages.append($0) }
        return (succeeded, messages)
    }

    private func withPicture(more: [String: String] = [:]) -> FakeFileSystem {
        FakeFileSystem(texts: more.merging([Self.source: "picture"]) { $1 })
    }

    @Test func noSettingChangesNothing() async {
        let runner = dscl()
        let (succeeded, messages) = await set([:], files: withPicture(), runner: runner)
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }

    @Test func macOSPictureIsReplacedAndStoredInTheAccount() async {
        let files = withPicture()
        let runner = dscl()
        let (succeeded, messages) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(files.allPaths.contains(kept()))
        #expect(
            runner.commands.suffix(3).map(\.arguments) == [
                ["-n", Dscl.path, ".", "-create", "/Users/test", "Picture", kept()],
                ["-n", Dscl.path, ".", "-delete", "/Users/test", "JPEGPhoto"],
                ["-n", Dsimport.path, importFile, "/Local/Default", "M"],
            ])
        #expect(!files.allPaths.contains(importFile))
        #expect(messages.last == Message(.info, "set your user picture to me.png from pictures in dots"))
    }

    @Test func pictureAlreadySetChangesNothing() async {
        let files = withPicture(more: [kept(): "square"])
        let runner = dscl(current: Self.showing(kept()))
        let (succeeded, messages) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands == [Dscl.readPicture(of: "test")])
    }

    @Test func newPictureReplacesTheOldOne() async {
        let old = kept(Data("old".utf8))
        let files = withPicture(more: [old: "old"])
        let runner = dscl(current: Self.showing(old), hasPhoto: false)
        let (succeeded, _) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(!files.allPaths.contains(old))
        #expect(
            runner.commands.suffix(2).map(\.arguments) == [
                ["-n", Dscl.path, ".", "-create", "/Users/test", "Picture", kept()],
                ["-n", Dsimport.path, importFile, "/Local/Default", "M"],
            ])
    }

    @Test func missingPictureIsAnError() async {
        let runner = dscl()
        let (succeeded, messages) = await set(files: FakeFileSystem(), runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't set your user picture: there's no picture called me in \(Self.folder)")
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func unreadablePictureIsAnError() async {
        let pictures = FakeSquarePictures(failure: .unreadable(path: Self.source))
        let (succeeded, messages) = await set(files: withPicture(), runner: dscl(), pictures: pictures)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't set your user picture: \(Self.source) isn't a picture macOS can read")
            ])
    }

    @Test func refusedPictureIsAnError() async {
        let (succeeded, messages) = await set(files: withPicture(), runner: dscl(failing: true))
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't set your user picture: \(Self.setFailure)"))
    }
}
