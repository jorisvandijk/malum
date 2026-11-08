import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppPreferenceWriterTests {
    private let domain = "com.if.Amphetamine"
    private let files = FakeFileSystem()

    private var state: StateFolder {
        StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/test"))
    }

    /// An export of `domain` holding `entries`, plist elements keyed by name.
    nonisolated private static func export(_ entries: String = "") -> CommandResult {
        CommandResult(
            status: 0,
            output: """
                <?xml version="1.0" encoding="UTF-8"?>
                <plist version="1.0"><dict>\(entries)</dict></plist>
                """)
    }

    /// `Hide Dock Icon = flag` as amphetamine's file sets it.
    private func hideDockIcon(_ flag: Bool) -> (app: String, preference: AppPreference) {
        let value = PlistText.document(.boolean(flag)) ?? ""
        return ("amphetamine", AppPreference(domain: domain, key: "Hide Dock Icon", value: value))
    }

    /// Writes `wanted` with `runner`, and gives back whether it worked and what it said.
    private func write(
        _ wanted: [(app: String, preference: AppPreference)], runner: FakeRunner, keeping: Set<String> = []
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let sudo = SudoSession(runner: runner, canAsk: true)
        defer { sudo.end() }
        let writer = AppPreferenceWriter(runner: runner, files: files, sudo: sudo, state: state)
        let succeeded = await writer.write(wanted, keeping: keeping) { messages.append($0) }
        return (succeeded, messages)
    }

    private var managed: [String: ManagedPreferences] {
        ((try? InstalledRecord.read(from: state)) ?? InstalledRecord()).preferences
    }

    @Test func newPreferenceIsSetAndRecorded() async {
        let runner = FakeRunner { _ in Self.export() }
        let (succeeded, messages) = await write([hideDockIcon(true)], runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Defaults.export(domain), Defaults.write(domain, "Hide Dock Icon", hideDockIcon(true).preference.value),
            ])
        #expect(
            messages == [
                Message(.info, "set Hide Dock Icon in com.if.Amphetamine from apps/amphetamine.toml"),
                Message(
                    .info, "amphetamine reads its preferences when it starts: quit and reopen it to use the new ones"),
            ])
        #expect(managed == [domain: ManagedPreferences(app: "amphetamine", keys: ["Hide Dock Icon"])])
    }

    @Test func matchingPreferenceIsTakenOverQuietly() async {
        let runner = FakeRunner { _ in Self.export("<key>Hide Dock Icon</key><true/>") }
        let (succeeded, messages) = await write([hideDockIcon(true)], runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Defaults.export(domain)])
        #expect(messages == [Message(.info, "every app preference is up to date")])
        #expect(managed == [domain: ManagedPreferences(app: "amphetamine", keys: ["Hide Dock Icon"])])
    }

    @Test func changedPreferenceIsSetBack() async {
        let runner = FakeRunner { _ in Self.export("<key>Hide Dock Icon</key><false/>") }
        let (_, messages) = await write([hideDockIcon(true)], runner: runner)
        #expect(runner.commands.count == 2)
        #expect(messages.first == Message(.info, "set Hide Dock Icon in com.if.Amphetamine from apps/amphetamine.toml"))
    }

    @Test func droppedPreferenceIsRemoved() async {
        _ = await write([hideDockIcon(true)], runner: FakeRunner { _ in Self.export() })
        let runner = FakeRunner { _ in Self.export("<key>Hide Dock Icon</key><true/>") }
        let (succeeded, messages) = await write([], runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Defaults.export(domain), Defaults.delete(domain, "Hide Dock Icon")])
        #expect(
            messages.first
                == Message(
                    .info,
                    "removed Hide Dock Icon from com.if.Amphetamine, apps/amphetamine.toml doesn't set it anymore"))
        #expect(managed.isEmpty)
    }

    @Test func brokenAppKeepsItsPreferences() async {
        _ = await write([hideDockIcon(true)], runner: FakeRunner { _ in Self.export() })
        let runner = FakeRunner()
        let (succeeded, _) = await write([], runner: runner, keeping: ["amphetamine"])
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(managed.count == 1)
    }

    @Test func unreadableDomainIsAnError() async {
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "no such domain") }
        let (succeeded, messages) = await write([hideDockIcon(true)], runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [Message(.error, "couldn't read the preferences in com.if.Amphetamine: no such domain")])
    }

    @Test func valuesBecomePlistElements() {
        let table: ConfigValue = .table(["b": .array([.integer(1), .float(1.5)]), "a": .string("<&>")])
        #expect(
            PlistText.document(table)?.hasSuffix(
                "<plist version=\"1.0\"><dict><key>a</key><string>&lt;&amp;&gt;</string>"
                    + "<key>b</key><array><integer>1</integer><real>1.5</real></array></dict></plist>") == true)
        #expect(PlistText.document(.date("2026-11-05")) == nil)
    }

    @Test func systemWidePreferenceIsSetAsRoot() async {
        let domain = "/Library/Preferences/net.librewolf.librewolf"
        let value = PlistText.document(.boolean(true)) ?? ""
        let runner = FakeRunner()
        let (succeeded, messages) = await write(
            [("librewolf", AppPreference(domain: domain, key: "DisableTelemetry", value: value))], runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Sudo.authorize, Sudo.asRoot(Defaults.write(domain, "DisableTelemetry", value))])
        #expect(
            messages.prefix(2) == [
                Message(.info, "asking for your password to set system-wide app preferences"),
                Message(.info, "set DisableTelemetry in \(domain) from apps/librewolf.toml"),
            ])
        #expect(managed == [domain: ManagedPreferences(app: "librewolf", keys: ["DisableTelemetry"])])
    }

    @Test func refusedPasswordSetsNoSystemWidePreference() async {
        let domain = "/Library/Preferences/net.librewolf.librewolf"
        let runner = FakeRunner { $0 == Sudo.authorize ? CommandResult(status: 1) : CommandResult(status: 0) }
        let (succeeded, messages) = await write(
            [("librewolf", AppPreference(domain: domain, key: "DisableTelemetry", value: ""))], runner: runner)
        #expect(!succeeded)
        #expect(runner.commands == [Sudo.authorize])
        #expect(messages.last == Message(.error, "couldn't set system-wide app preferences: sudo wasn't granted"))
        #expect(managed.isEmpty)
    }
}
