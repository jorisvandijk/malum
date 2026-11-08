import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppleAppsTests {
    private static let garageBand = "/Applications/GarageBand.app"
    private static let pages = "/Applications/Pages.app"

    /// A disk where each app at a path in `ids` has that bundle ID.
    private static func files(_ ids: [String: String]) -> FakeFileSystem {
        var texts: [String: String] = [:]
        for (path, id) in ids {
            texts["\(path)/Contents/Info.plist"] = AppBundleTests.info(bundleID: id, version: "1.0")
        }
        return FakeFileSystem(texts: texts)
    }

    /// Removes `names` from a disk with the bundle IDs `ids`, and gives back whether it worked and
    /// what it said.
    private func remove(_ names: [String], ids: [String: String], runner: FakeRunner) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let apps = AppleApps(runner: runner, files: Self.files(ids), sudo: SudoSession(runner: runner, canAsk: true))
        let succeeded = await apps.remove(names) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func removesAppleAppsAsRootAndSkipsMissingOnes() async {
        let runner = FakeRunner()
        let ids = [Self.garageBand: "com.apple.garageband10"]
        let (succeeded, messages) = await remove(["iMovie", "GarageBand"], ids: ids, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Sudo.authorize, Sudo.asRoot(Command("/bin/rm", ["-rf", Self.garageBand])),
            ])
        #expect(
            messages == [
                Message(.info, "asking for your password to remove Apple apps"),
                Message(.info, "removed /Applications/GarageBand.app, it's in [apple_apps] remove in macos.toml"),
            ])
    }

    @Test func appThatIsntApplesStays() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await remove(["Pages"], ids: [Self.pages: "com.example.pages"], runner: runner)
        #expect(!succeeded)
        #expect(runner.commands.isEmpty)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't remove /Applications/Pages.app: it isn't an Apple app, its bundle ID is com.example.pages"
                )
            ])
    }

    @Test func readsTheListAndRejectsBadNames() {
        let (wanted, _) = MacOSSettings.read("[apple_apps]\nremove = [\"GarageBand\", \"iMovie\"]\n")
        #expect(wanted?.appleApps == ["GarageBand", "iMovie"])
        let (bad, problems) = MacOSSettings.read("[apple_apps]\nremove = [\"../Xcode\"]\nkeep = []\n")
        #expect(bad == nil)
        #expect(
            problems.map(\.message) == [
                Message(
                    .error, "macos.toml line 2: apple_apps.remove: the name can't be empty, start with a dot or hold /"),
                Message(.warn, "macos.toml line 3: unknown setting apple_apps.keep"),
            ])
    }
}
