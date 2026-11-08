import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct DefaultAppsTests {
    private let browser = "net.librewolf.librewolf"
    private let browserTargets: [OpenTarget] = [
        .scheme("http"), .scheme("https"), .contentType("public.html"), .contentType("public.xhtml"),
    ]

    /// Reads `text` as `macos.toml`: what `[default_apps]` sets and every problem.
    private func read(_ text: String) -> (DefaultApps.Wanted, [Message]) {
        guard var reader = try? TableReader(text, file: Paths.macOSTOMLName) else { return ([:], []) }
        let wanted = DefaultApps.read(&reader)
        return (wanted, reader.problems.map(\.message))
    }

    /// Sets `wanted` through `handlers`, and gives back whether it worked and what it said.
    private func set(_ wanted: DefaultApps.Wanted, _ handlers: FakeAppHandlers) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let succeeded = await DefaultApps(handlers: handlers).set(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func readsBrowserAndVideo() {
        let (wanted, problems) = read("[default_apps]\nbrowser = \"\(browser)\"\nvideo = \"io.mpv\"\n")
        #expect(problems.isEmpty)
        #expect(wanted == ["browser": browser, "video": "io.mpv"])
    }

    @Test func badEntriesAreProblems() {
        let (wanted, problems) = read("[default_apps]\nbrowser = 3\nvideo = \"io mpv\"\nmail = \"x\"\n")
        #expect(wanted.isEmpty)
        #expect(
            problems.sorted { $0.description < $1.description } == [
                Message(.error, "macos.toml line 2: default_apps.browser should be text in quotes"),
                Message(.error, "macos.toml line 3: default_apps.video: a bundle ID can't be empty or hold spaces"),
                Message(.warn, "macos.toml line 4: unknown setting default_apps.mail"),
            ])
    }

    @Test func setsEveryBrowserTargetAndAsksToConfirm() async {
        let handlers = FakeAppHandlers(installed: [browser], handlers: [.scheme("http"): "com.apple.Safari"])
        let (succeeded, messages) = await set(["browser": browser], handlers)
        #expect(succeeded)
        #expect(handlers.set == browserTargets)
        #expect(
            messages.prefix(2) == [
                Message(.info, "macOS asks you to confirm \(browser) as the default browser, in a dialog of its own"),
                Message(.info, "made \(browser) the default app for http links from macos.toml"),
            ])
        #expect(
            messages.last == Message(.info, "made \(browser) the default app for public.xhtml files from macos.toml"))
    }

    @Test func alreadySetChangesNothing() async {
        let handlers = FakeAppHandlers(
            installed: [browser], handlers: Dictionary(uniqueKeysWithValues: browserTargets.map { ($0, browser) }))
        let (succeeded, messages) = await set(["browser": browser], handlers)
        #expect(succeeded)
        #expect(handlers.set.isEmpty)
        #expect(messages.isEmpty)
    }

    @Test func unknownFileTypesAreSkipped() async {
        let handlers = FakeAppHandlers(installed: ["io.mpv"], unknown: ["org.matroska.mkv"])
        let (succeeded, _) = await set(["video": "io.mpv"], handlers)
        #expect(succeeded)
        #expect(handlers.set.count == 6)
        #expect(!handlers.set.contains(.contentType("org.matroska.mkv")))
    }

    @Test func missingAppIsAnError() async {
        let (succeeded, messages) = await set(["video": "io.mpv"], FakeAppHandlers())
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't set default_apps.video in macos.toml to io.mpv: no app with that bundle ID is installed")
            ])
    }

    @Test func refusedBrowserStopsAsking() async {
        let handlers = FakeAppHandlers(installed: [browser], refused: [.scheme("http")])
        let (succeeded, messages) = await set(["browser": browser], handlers)
        #expect(!succeeded)
        #expect(handlers.set.isEmpty)
        #expect(
            messages.last
                == Message(
                    .error, "couldn't make \(browser) the default app for http links: the user kept the current one"))
    }
}
