import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct MarkEditExtensionsTests {
    private let registry = "https://raw.githubusercontent.com/MarkEdit-app/extensions/main/index.json"
    private let scripts = "/Users/test/Library/Containers/app.cyan.markedit/Data/Documents/scripts"
    private let previewURL = "https://example.com/markedit-preview.js"
    private let vimURL = "https://example.com/markedit-vim.js"

    /// The registry, with markedit-preview at `previewVersion` and markedit-vim at 1.1.0.
    private func index(previewVersion: String = "1.14.1") -> String {
        """
        {"schemaVersion": 1, "extensions": [
          {"id": "markedit-preview", "name": "View Modes", "latest": {"version": "\(previewVersion)",
           "url": "\(previewURL)", "sha256": "AAA"}},
          {"id": "markedit-vim", "latest": {"version": "1.1.0", "url": "\(vimURL)", "sha256": "bbb"}}
        ]}
        """
    }

    /// A runner whose `shasum` gives the checksum the registry has for each download, except
    /// for `wrong`.
    private func shasum(wrong: String? = nil) -> FakeRunner {
        FakeRunner { command in
            let file = command.arguments.last ?? ""
            let sum = file.hasSuffix("/markedit-preview.js") ? "aaa" : "bbb"
            return CommandResult(
                status: 0, output: file.hasSuffix("/\(wrong ?? "-").js") ? "ccc  x" : "\(sum)  \(file)")
        }
    }

    private func state(_ files: FakeFileSystem) -> StateFolder {
        StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/test"))
    }

    private func run(
        _ ids: [String], files: FakeFileSystem, index: String? = nil, runner: FakeRunner? = nil
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let github = FakeGitHub(
            [:], files: files,
            served: [registry: index ?? self.index(), previewURL: "preview script", vimURL: "vim script"])
        let succeeded = await MarkEditExtensions(
            github: github, runner: runner ?? shasum(), files: files, state: state(files), scripts: scripts
        ).run(ids) { messages.append($0) }
        return (succeeded, messages)
    }

    private func managed(_ files: FakeFileSystem) -> [String: String] {
        ((try? InstalledRecord.read(from: state(files))) ?? InstalledRecord()).markEditExtensions
    }

    @Test func nothingListedOrManagedDoesNothing() async {
        let files = FakeFileSystem()
        let (succeeded, messages) = await run([], files: files)
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(files.allPaths.isEmpty)
    }

    @Test func listedOnesAreInstalledAndRecorded() async {
        let files = FakeFileSystem()
        let (succeeded, messages) = await run(["markedit-preview", "markedit-vim"], files: files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "installed MarkEdit extension markedit-preview 1.14.1"),
                Message(.info, "installed MarkEdit extension markedit-vim 1.1.0"),
            ])
        #expect(files.text(at: "\(scripts)/markedit-preview.js") == "preview script")
        #expect(files.text(at: "\(scripts)/markedit-vim.js") == "vim script")
        #expect(managed(files) == ["markedit-preview": "1.14.1", "markedit-vim": "1.1.0"])
    }

    @Test func secondRunIsUpToDate() async {
        let files = FakeFileSystem()
        _ = await run(["markedit-preview"], files: files)
        let (succeeded, messages) = await run(["markedit-preview"], files: files)
        #expect(succeeded)
        #expect(messages == [Message(.info, "every listed MarkEdit extension is up to date")])
    }

    @Test func newerVersionIsInstalledOverTheOldOne() async throws {
        let files = FakeFileSystem()
        _ = await run(["markedit-preview"], files: files)
        try files.write("old", to: "\(scripts)/markedit-preview.js")
        let (succeeded, messages) = await run(["markedit-preview"], files: files, index: index(previewVersion: "2.0.0"))
        #expect(succeeded)
        #expect(messages == [Message(.info, "installed MarkEdit extension markedit-preview 2.0.0")])
        #expect(files.text(at: "\(scripts)/markedit-preview.js") == "preview script")
    }

    @Test func unlistedOneIsRemoved() async {
        let files = FakeFileSystem()
        _ = await run(["markedit-preview", "markedit-vim"], files: files)
        let (succeeded, messages) = await run(["markedit-preview"], files: files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "removed MarkEdit extension markedit-vim"),
                Message(.info, "every listed MarkEdit extension is up to date"),
            ])
        #expect(files.item(at: "\(scripts)/markedit-vim.js") == nil)
        #expect(managed(files) == ["markedit-preview": "1.14.1"])
    }

    @Test func wrongChecksumInstallsNothing() async {
        let files = FakeFileSystem()
        let (succeeded, messages) = await run(["markedit-vim"], files: files, runner: shasum(wrong: "markedit-vim"))
        #expect(!succeeded)
        let reason = "the download of markedit-vim doesn't match the checksum MarkEdit's registry gives"
        #expect(messages.map(\.text.description) == ["couldn't install MarkEdit extension markedit-vim: \(reason)"])
        #expect(files.item(at: "\(scripts)/markedit-vim.js") == nil)
        #expect(managed(files).isEmpty)
    }

    @Test func unknownIdIsAnError() async {
        let (succeeded, messages) = await run(["markedit-nope"], files: FakeFileSystem())
        #expect(!succeeded)
        let reason = "MarkEdit's registry has no extension called markedit-nope"
        #expect(messages.map(\.text.description) == ["couldn't install MarkEdit extension markedit-nope: \(reason)"])
    }

    @Test func unreadableRegistryIsAnError() async {
        let (succeeded, messages) = await run(["markedit-vim"], files: FakeFileSystem(), index: "<html>")
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't read MarkEdit's list of extensions: MarkEdit's registry sent a list Malum can't read")
            ])
    }

    @Test func idsAreLettersDigitsAndDashes() {
        #expect(MarkEditExtensions.isID("markedit-theme-one-dark"))
        #expect(!MarkEditExtensions.isID("../evil"))
        #expect(!MarkEditExtensions.isID(""))
    }
}
