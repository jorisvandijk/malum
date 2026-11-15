import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct StartupAppsTests {
    private let paths = Paths(home: "/Users/test")
    private let pointer = "/Users/test/.config/malum/config"
    private let file = "/Users/test/dots/macos.toml"

    /// Opens the startup apps of `macos` with `apps`, and gives back what it said.
    private func open(_ macos: String?, apps: FakeAppControl) async -> [Message] {
        var texts = [pointer: "/Users/test/dots\n"]
        texts[file] = macos
        var messages: [Message] = []
        await StartupApps(files: FakeFileSystem(texts: texts), paths: paths, apps: apps).open { messages.append($0) }
        return messages
    }

    @Test func appsThatDontRunAreOpened() async {
        let apps = FakeAppControl()
        apps.running["com.if.Amphetamine"] = RunningApp(
            pid: 7, bundleID: "com.if.Amphetamine", name: "Amphetamine", isActive: false, isHidden: false,
            isRegular: true)
        let messages = await open(
            "[startup]\napps = [\"com.if.Amphetamine\", \"com.sindresorhus.Command-X\"]\n", apps: apps)
        #expect(apps.calls == ["open com.sindresorhus.Command-X"])
        #expect(messages == [Message(.info, "opened com.sindresorhus.Command-X at start")])
    }

    @Test func noListOpensNothing() async {
        let apps = FakeAppControl()
        #expect(await open(nil, apps: apps).isEmpty)
        #expect(await open("[display]\nresolution = \"1710x1112\"\n", apps: apps).isEmpty)
        #expect(apps.calls.isEmpty)
    }

    @Test func wrongListIsReportedAndOpensNothing() async {
        let apps = FakeAppControl()
        let messages = await open("[startup]\napps = [\"not an id\"]\n", apps: apps)
        #expect(apps.calls.isEmpty)
        #expect(
            messages == [Message(.error, "macos.toml line 2: startup.apps: a bundle ID can't be empty or hold spaces")])
    }

    @Test func appThatWontOpenIsAWarning() async {
        let apps = FakeAppControl()
        apps.openError = .notInstalled("com.example.gone")
        let messages = await open("[startup]\napps = [\"com.example.gone\"]\n", apps: apps)
        #expect(messages.map(\.level) == [.warn])
    }
}
