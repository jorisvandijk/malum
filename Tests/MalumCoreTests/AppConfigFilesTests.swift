import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppConfigFilesTests {
    private let home = "/Users/joris"
    private let toml = "/Users/joris/dots/apps/git.toml"
    private let config = "/Users/joris/.config/git/config"
    private let backup = "/Users/joris/.config/git/config.backup"
    private let header =
        "# Written by Malum from apps/git.toml in dots. Changes made here are overwritten.\n"
    private let settings = "[settings.init]\ndefaultBranch = \"main\"\n"
    private var written: String { header + "[init]\n\tdefaultBranch = \"main\"\n" }

    private func state(_ files: FakeFileSystem) -> StateFolder {
        StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: home))
    }

    /// Runs the part on `files`, and gives back whether it worked and what it said.
    private func run(_ files: FakeFileSystem) -> (Bool, [Message]) {
        var messages: [Message] = []
        let succeeded = AppConfigFiles(files: files, state: state(files), paths: Paths(home: home)).run(
            dots: "/Users/joris/dots"
        ) { messages.append($0) }
        return (succeeded, messages)
    }

    private func managed(_ files: FakeFileSystem) -> [String: ManagedFile] {
        ((try? InstalledRecord.read(from: state(files))) ?? InstalledRecord()).files
    }

    @Test func missingFolderWritesNothing() {
        let (succeeded, messages) = run(FakeFileSystem())
        #expect(succeeded)
        #expect(messages == [Message(.info, "no app config files to write: /Users/joris/dots/apps doesn't exist")])
    }

    @Test func newFileIsWrittenAndRecorded() {
        let files = FakeFileSystem(texts: [toml: settings])
        let (succeeded, messages) = run(files)
        #expect(succeeded)
        #expect(messages == [Message(.info, "wrote \(config) from apps/git.toml")])
        #expect(files.text(at: config) == written)
        #expect(managed(files)[config] == ManagedFile(app: "git", text: written))
    }

    @Test func secondRunChangesNothing() {
        let files = FakeFileSystem(texts: [toml: settings])
        _ = run(files)
        let (succeeded, messages) = run(files)
        #expect(succeeded)
        #expect(messages == [Message(.info, "every app config file is up to date")])
    }

    @Test func changedSettingUpdatesTheFile() {
        let files = FakeFileSystem(texts: [toml: settings])
        _ = run(files)
        try? files.write("[settings.init]\ndefaultBranch = \"trunk\"\n", to: toml)
        let (_, messages) = run(files)
        #expect(messages == [Message(.info, "updated \(config) from apps/git.toml")])
        #expect(files.text(at: config) == header + "[init]\n\tdefaultBranch = \"trunk\"\n")
    }

    @Test func matchingFileIsTakenOverQuietly() {
        let files = FakeFileSystem(texts: [toml: settings, config: written])
        let (_, messages) = run(files)
        #expect(messages == [Message(.info, "\(config) already matched apps/git.toml, Malum manages it now")])
        #expect(managed(files)[config] != nil)
    }

    @Test func differentFileIsTakenOverAndKept() {
        let files = FakeFileSystem(texts: [toml: settings, config: "[user]\n\tname = me\n"])
        let (succeeded, messages) = run(files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(
                    .warn,
                    "\(config) was already there and differed from apps/git.toml, see what changed with: diff \(backup) \(config)"
                )
            ])
        #expect(files.text(at: config) == written)
        #expect(files.text(at: backup) == "[user]\n\tname = me\n")
    }

    @Test func fileChangedOutsideMalumIsOverwrittenAndKept() {
        let files = FakeFileSystem(texts: [toml: settings])
        _ = run(files)
        try? files.write("changed\n", to: config)
        let (_, messages) = run(files)
        #expect(
            messages == [
                Message(
                    .warn,
                    "\(config) was changed outside Malum, so it was overwritten from apps/git.toml, see what changed with: diff \(backup) \(config)"
                )
            ])
        #expect(files.text(at: config) == written)
        #expect(files.text(at: backup) == "changed\n")
    }

    @Test func deletedFileIsWrittenAgain() {
        let files = FakeFileSystem(texts: [toml: settings])
        _ = run(files)
        try? files.remove(config)
        let (_, messages) = run(files)
        #expect(messages == [Message(.warn, "\(config) was deleted outside Malum, wrote it again from apps/git.toml")])
        #expect(files.text(at: config) == written)
    }

    @Test func linkIsReplacedByTheFile() {
        let files = FakeFileSystem(items: [config: .link(to: "/Users/joris/dots/gitconfig")], texts: [toml: settings])
        let (_, messages) = run(files)
        #expect(
            messages == [
                Message(.info, "wrote \(config) from apps/git.toml, replacing a link to /Users/joris/dots/gitconfig")
            ])
        #expect(files.item(at: config) == .file)
    }

    @Test func folderInTheWayIsAnError() {
        let files = FakeFileSystem(items: [config + "/x": .file], texts: [toml: settings])
        let (succeeded, messages) = run(files)
        #expect(!succeeded)
        #expect(
            messages == [Message(.error, "couldn't write git's config file: couldn't write \(config): it's a folder")])
    }

    @Test func droppedFileIsRemoved() {
        let files = FakeFileSystem(texts: [toml: "[ignore]\npatterns = [\"*.swp\"]\n"])
        _ = run(files)
        try? files.write("", to: toml)
        let (succeeded, messages) = run(files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "removed /Users/joris/.config/git/ignore, apps/git.toml doesn't write it anymore")
            ])
        #expect(files.item(at: "/Users/joris/.config/git/ignore") == nil)
        #expect(managed(files)["/Users/joris/.config/git/ignore"] == nil)
    }

    @Test func droppedFileChangedOutsideMalumStays() {
        let ignore = "/Users/joris/.config/git/ignore"
        let files = FakeFileSystem(texts: [toml: "[ignore]\npatterns = [\"*.swp\"]\n"])
        _ = run(files)
        try? files.write("mine\n", to: ignore)
        try? files.remove(toml)
        try? files.createDirectory("/Users/joris/dots/apps")
        let (_, messages) = run(files)
        let warning: MessageText = """
            \(ignore) isn't written from apps/git.toml anymore, but it was changed outside Malum, so it stays \
            and Malum no longer manages it
            """
        #expect(
            messages == [
                Message(.info, "removed \(config), apps/git.toml doesn't write it anymore"),
                Message(.warn, warning),
            ])
        #expect(files.text(at: ignore) == "mine\n")
        #expect(managed(files).isEmpty)
    }

    @Test func errorKeepsTheAppsFiles() {
        let files = FakeFileSystem(texts: [toml: settings])
        _ = run(files)
        try? files.write("settings = 1\n", to: toml)
        let (succeeded, messages) = run(files)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "apps/git.toml line 1: settings should be a table"),
                Message(.error, "couldn't write git's config files: fix \(toml) first"),
            ])
        #expect(files.text(at: config) == written)
    }

    @Test func syntaxErrorIsReportedWithItsLine() {
        let files = FakeFileSystem(texts: [toml: "[settings\n"])
        let (succeeded, messages) = run(files)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't write git's config files: fix \(toml) first"))
        #expect(messages.first?.text.description.hasPrefix("apps/git.toml line 1") == true)
    }

    @Test func unknownAppIsAWarning() {
        let files = FakeFileSystem(texts: [
            "/Users/joris/dots/apps/vim.toml": "", "/Users/joris/dots/apps/notes.txt": "",
        ])
        let (succeeded, messages) = run(files)
        #expect(succeeded)
        #expect(messages == [Message(.warn, "apps/vim.toml: Malum has no app called vim")])
    }

    @Test func pathWithSpacesIsQuotedInTheDiffCommand() {
        let toml = "/Users/joris/dots/apps/git.toml"
        let files = FakeFileSystem(texts: [toml: settings, "/Users/jo ris/.config/git/config": "old\n"])
        var messages: [Message] = []
        _ = AppConfigFiles(
            files: files, state: StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/jo ris")),
            paths: Paths(home: "/Users/jo ris")
        ).run(dots: "/Users/joris/dots") { messages.append($0) }
        #expect(
            messages.first?.text.description.hasSuffix(
                "see what changed with: diff '/Users/jo ris/.config/git/config.backup' '/Users/jo ris/.config/git/config'"
            )
                == true)
    }
}
