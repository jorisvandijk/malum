import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SystemFileWriterTests {
    private let paths = Paths(home: "/Users/joris")
    private let hosts = SystemFile.hosts.path
    private let sudoLocal = SystemFile.sudoLocal.path
    private let staged = "/Users/joris/Library/Application Support/\(Project.bundleID)/system-file.staged"

    /// Writes `wanted` on `files` with `runner`, and gives back whether it worked and what it said.
    private func write(
        _ wanted: [String: String], _ files: FakeFileSystem, runner: FakeRunner = FakeRunner(),
        canAsk: Bool = true
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let writer = SystemFileWriter(
            runner: runner, files: files, sudo: SudoSession(runner: runner, canAsk: canAsk), state: state)
        let succeeded = await writer.write(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    private func record(_ files: FakeFileSystem) -> [String: String] {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return ((try? InstalledRecord.read(from: state)) ?? InstalledRecord()).systemFiles
    }

    /// `files` with `text` recorded as what Malum wrote at `path`.
    private func recorded(_ text: String, at path: String, _ files: FakeFileSystem) -> FakeFileSystem {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        try? InstalledRecord.change(in: state) { $0.systemFiles[path] = ManagedFile.fingerprint(of: text) }
        return files
    }

    private static let asking = Message(
        .info, "asking for your password to change /etc/hosts or Touch ID for sudo")

    @Test func writesTouchIDAsRoot() async {
        let runner = FakeRunner()
        let files = FakeFileSystem()
        let (succeeded, messages) = await write([sudoLocal: SystemFile.touchID], files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Sudo.authorize, Sudo.asRoot(Install.rootFile(staged, to: sudoLocal))])
        #expect(messages == [Self.asking, Message(.info, "wrote /etc/pam.d/sudo_local from macos.toml")])
        #expect(record(files) == [sudoLocal: ManagedFile.fingerprint(of: SystemFile.touchID)])
    }

    @Test func overwritesHostsAfterKeepingTheOldOneAndRereadsIt() async {
        let runner = FakeRunner()
        let files = FakeFileSystem(texts: [hosts: "127.0.0.1 localhost\n"])
        let wanted = SystemFile.hosts([("nas.home", "10.0.0.2")])
        let (succeeded, messages) = await write([hosts: wanted], files, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Sudo.authorize, Sudo.asRoot(Install.rootFile(hosts, to: "/etc/hosts.backup")),
                Sudo.asRoot(Install.rootFile(staged, to: hosts)), Sudo.asRoot(DSCacheUtil.flush),
                Sudo.asRoot(Killall.hangUp("mDNSResponder")),
            ])
        #expect(
            messages.last
                == Message(
                    .warn,
                    """
                    /etc/hosts was already there and differed from macos.toml, see what changed with: \
                    diff /etc/hosts.backup /etc/hosts
                    """))
        #expect(record(files)[hosts] == ManagedFile.fingerprint(of: wanted))
        #expect(files.item(at: staged) == nil)
    }

    @Test func fileAlreadyRightIsOnlyRecorded() async {
        let runner = FakeRunner()
        let files = FakeFileSystem(texts: [sudoLocal: SystemFile.touchID])
        let (succeeded, messages) = await write([sudoLocal: SystemFile.touchID], files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages == [Message(.info, "/etc/pam.d/sudo_local already matched macos.toml, Malum manages it now")])
        let (again, quiet) = await write([sudoLocal: SystemFile.touchID], files, runner: runner)
        #expect(again && quiet.isEmpty)
    }

    @Test func droppedFilesGoBackToMacOSOwn() async {
        let runner = FakeRunner()
        let files = recorded(
            SystemFile.touchID, at: sudoLocal,
            recorded("custom\n", at: hosts, FakeFileSystem(texts: [hosts: "custom\n", sudoLocal: SystemFile.touchID])))
        let (succeeded, messages) = await write([:], files, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Sudo.authorize, Sudo.asRoot(Install.rootFile(staged, to: hosts)), Sudo.asRoot(DSCacheUtil.flush),
                Sudo.asRoot(Killall.hangUp("mDNSResponder")), Sudo.asRoot(Remove.file(sudoLocal)),
            ])
        #expect(
            messages.dropFirst() == [
                Message(.info, "put back macOS's own /etc/hosts, macos.toml doesn't set it anymore"),
                Message(.info, "removed /etc/pam.d/sudo_local, macos.toml doesn't write it anymore"),
            ])
        #expect(record(files).isEmpty)
    }

    @Test func droppedFileChangedByHandIsLetGo() async {
        let runner = FakeRunner()
        let files = recorded(SystemFile.touchID, at: sudoLocal, FakeFileSystem(texts: [sudoLocal: "mine\n"]))
        let (succeeded, messages) = await write([:], files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages.map(\.level) == [.warn])
        #expect(record(files).isEmpty)
    }

    @Test func noPasswordChangesNothing() async {
        let runner = FakeRunner()
        let files = FakeFileSystem()
        let (succeeded, _) = await write([sudoLocal: SystemFile.touchID], files, runner: runner, canAsk: false)
        #expect(!succeeded)
        #expect(runner.commands.isEmpty)
        #expect(record(files).isEmpty)
    }

    @Test func failedInstallIsReportedAndNotRecorded() async {
        let runner = FakeRunner { $0 == Sudo.authorize ? CommandResult(status: 0) : CommandResult(status: 1) }
        let files = FakeFileSystem()
        let (succeeded, messages) = await write([sudoLocal: SystemFile.touchID], files, runner: runner)
        #expect(!succeeded)
        #expect(messages.last?.text.description.hasPrefix("couldn't change /etc/pam.d/sudo_local: ") == true)
        #expect(record(files).isEmpty)
    }
}
