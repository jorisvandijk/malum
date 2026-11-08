import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppleAppsTests {
    private static let garageBand = "/Applications/GarageBand.app"
    private static let pages = "/Applications/Pages.app"
    private static let files = FakeFileSystem(
        items: ["\(garageBand)/Contents": .directory, "\(pages)/Contents": .directory])

    /// A runner that gives each app at `path` the bundle ID in `ids`.
    private static func runner(_ ids: [String: String]) -> FakeRunner {
        FakeRunner { command in
            guard
                let path = ids.keys.first(where: {
                    command == Defaults.read("\($0)/Contents/Info", "CFBundleIdentifier")
                })
            else { return CommandResult(status: 0) }
            return CommandResult(status: 0, output: (ids[path] ?? "") + "\n")
        }
    }

    /// Removes `names` with `runner`, and gives back whether it worked and what it said.
    private func remove(_ names: [String], runner: FakeRunner) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let apps = AppleApps(runner: runner, files: Self.files, sudo: SudoSession(runner: runner, canAsk: true))
        let succeeded = await apps.remove(names) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func removesAppleAppsAsRootAndSkipsMissingOnes() async {
        let runner = Self.runner([Self.garageBand: "com.apple.garageband10"])
        let (succeeded, messages) = await remove(["iMovie", "GarageBand"], runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Defaults.read("\(Self.garageBand)/Contents/Info", "CFBundleIdentifier"), Sudo.authorize,
                Sudo.asRoot(Command("/bin/rm", ["-rf", Self.garageBand])),
            ])
        #expect(
            messages == [
                Message(.info, "asking for your password to remove Apple apps"),
                Message(.info, "removed /Applications/GarageBand.app, it's in [apple_apps] remove in macos.toml"),
            ])
    }

    @Test func appThatIsntApplesStays() async {
        let runner = Self.runner([Self.pages: "com.example.pages"])
        let (succeeded, messages) = await remove(["Pages"], runner: runner)
        #expect(!succeeded)
        #expect(runner.commands.count == 1)
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
