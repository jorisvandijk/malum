import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AccountPictureTests {
    private static let accounts = "/Users/test/Library/Preferences/MobileMeAccounts.plist"
    private static let cached = "/Users/test/Library/Caches/AAProfilePicture_ABC.png"
    private static let list = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict><key>Accounts</key><array>
        <dict><key>AccountUUID</key><string>ABC</string></dict>
        </array></dict></plist>
        """
    private static let cropList = "/Users/test/Library/Preferences/mbuseragent.plist"
    private static let crop = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict><key>kAOSUIProfilePictureCropRect</key>
        <string>{{117, 190}, {827, 827}}</string></dict></plist>
        """
    private static let switchedOn: ConfigTable = [AccountPicture.key: .boolean(true)]
    nonisolated private static let setFailure = "Cannot set the picture"
    private let paths = Paths(home: "/Users/test")

    /// Where Malum keeps the picture made from `data`.
    private func kept(_ data: Data = FakeSquarePictures.square) -> String {
        "\(paths.stateDirectory)/account-picture-\(Fingerprint.of(data)).jpg"
    }

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
        _ settings: ConfigTable = Self.switchedOn, files: FakeFileSystem, runner: FakeRunner,
        pictures: FakeSquarePictures = FakeSquarePictures()
    ) async -> (Bool, [Message]) {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        var messages: [Message] = []
        let succeeded = await AccountPicture(
            files: files, paths: paths, runner: runner, sudo: SudoSession(runner: runner, canAsk: true),
            state: state, pictures: pictures, user: "test"
        ).set(settings) { messages.append($0) }
        return (succeeded, messages)
    }

    private func signedIn(more: [String: String] = [:]) -> FakeFileSystem {
        FakeFileSystem(texts: more.merging([Self.accounts: Self.list, Self.cached: "picture"]) { $1 })
    }

    @Test func accountsCropIsUsed() async {
        let files = signedIn(more: [Self.cropList: Self.crop])
        let pictures = FakeSquarePictures()
        let (succeeded, _) = await set(files: files, runner: dscl(), pictures: pictures)
        #expect(succeeded)
        #expect(pictures.crop == PictureCrop(left: 117, bottom: 190, width: 827, height: 827))
    }

    @Test func switchedOffChangesNothing() async {
        let runner = dscl()
        let (succeeded, messages) = await set([:], files: signedIn(), runner: runner)
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }

    @Test func macOSPictureIsReplacedAndItsCopyRemoved() async {
        let files = signedIn()
        let runner = dscl()
        let (succeeded, messages) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(files.allPaths.contains(kept()))
        let importFile = "\(paths.stateDirectory)/account-picture.import"
        #expect(
            runner.commands.suffix(3).map(\.arguments) == [
                ["-n", Dscl.path, ".", "-create", "/Users/test", "Picture", kept()],
                ["-n", Dscl.path, ".", "-delete", "/Users/test", "JPEGPhoto"],
                ["-n", Dsimport.path, importFile, "/Local/Default", "M"],
            ])
        #expect(!files.allPaths.contains(importFile))
        #expect(messages.last == Message(.info, "your user picture is your Apple Account's picture now"))
    }

    @Test func pictureAlreadySetChangesNothing() async {
        let files = signedIn(more: [kept(): "square"])
        let runner = dscl(current: Self.showing(kept()))
        let (succeeded, messages) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands == [Dscl.readPicture(of: "test")])
    }

    @Test func newAccountPictureReplacesTheOldOneOnly() async {
        let old = kept(Data("old".utf8))
        let files = signedIn(more: [old: "old"])
        let runner = dscl(current: Self.showing(old), hasPhoto: false)
        let (succeeded, _) = await set(files: files, runner: runner)
        #expect(succeeded)
        #expect(!files.allPaths.contains(old))
        #expect(
            runner.commands.suffix(2).map(\.arguments) == [
                ["-n", Dscl.path, ".", "-create", "/Users/test", "Picture", kept()],
                ["-n", Dsimport.path, "\(paths.stateDirectory)/account-picture.import", "/Local/Default", "M"],
            ])
    }

    @Test func noAppleAccountWarns() async {
        let runner = dscl()
        let (succeeded, messages) = await set(files: FakeFileSystem(), runner: runner)
        #expect(succeeded)
        #expect(
            messages == [
                Message(
                    .warn,
                    """
                    couldn't set your user picture to your Apple Account's picture: no Apple Account picture yet, \
                    sign in to your Apple Account in System Settings
                    """)
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func unreadablePictureIsAnError() async {
        let pictures = FakeSquarePictures(failure: .unreadable(path: Self.cached))
        let (succeeded, messages) = await set(files: signedIn(), runner: dscl(), pictures: pictures)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    """
                    couldn't set your user picture to your Apple Account's picture: \(Self.cached) isn't a picture \
                    macOS can read
                    """)
            ])
    }

    @Test func refusedPictureIsAnError() async {
        let (succeeded, messages) = await set(files: signedIn(), runner: dscl(failing: true))
        #expect(!succeeded)
        #expect(
            messages.last
                == Message(.error, "couldn't set your user picture to your Apple Account's picture: \(Self.setFailure)")
        )
    }
}
