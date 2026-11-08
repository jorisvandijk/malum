/// Writes the files only root can change, from `macos.toml`, through the run's one password prompt.
///
/// Malum owns each file it writes: one changed outside Malum is overwritten, and the old one is
/// kept next to it with `.backup` added. When `macos.toml` stops setting a file, Malum puts back
/// macOS's own, unless it was changed outside Malum: then it stays, and Malum lets it go.
@MainActor
struct SystemFileWriter {
    /// What's added to a file's name for the copy of what was there before Malum overwrote it.
    private static let backupExtension = ".backup"
    /// The file in the state folder that's copied into place.
    private static let stagedName = "system-file.staged"

    /// Runs `install`, `rm` and what rereads `/etc/hosts`.
    private let runner: any CommandRunner
    /// The disk, where the files are read.
    private let files: any FileSystem
    /// Gets root.
    private let sudo: SudoSession
    /// Where the record is kept, and the file is staged.
    private let state: StateFolder

    /// Creates the writer, which reads on `files`, changes them as root with `runner` through
    /// `sudo`, and keeps its record in `state`.
    init(runner: any CommandRunner, files: any FileSystem, sudo: SudoSession, state: StateFolder) {
        self.runner = runner
        self.files = files
        self.sudo = sudo
        self.state = state
    }

    /// Makes each file hold its text in `wanted`, by path, and puts back macOS's own for each one
    /// Malum wrote that isn't in it. Says whether everything worked.
    func write(_ wanted: [String: String], report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: .setMacOSSettings, report: report) else {
            return false
        }
        var succeeded = true
        for file in SystemFile.all {
            let known = record.systemFiles[file.path]
            guard wanted[file.path] != nil || known != nil else { continue }
            let current: String?
            do {
                current = files.item(at: file.path) == .file ? try files.read(file.path) : nil
            } catch {
                report(.failed(.setMacOSSettings, error))
                succeeded = false
                continue
            }
            let changedOutside = current.map { ManagedFile.fingerprint(of: $0) != known } ?? false
            let result: Bool? =
                switch (wanted[file.path], changedOutside || current == nil) {
                case (let text?, _):
                    await put(text, at: file.path, current: current, known: known, report: report)
                case (nil, true):
                    letGo(file.path, changed: changedOutside, report: report)
                case (nil, false):
                    await putBack(file, report: report)
                }
            guard let result else { continue }
            succeeded = result && succeeded
            if result && file == .hosts { await rereadHosts(report: report) }
        }
        return succeeded
    }

    /// Writes `text` at `path`, which holds `current`, when it isn't there yet, and records it. Gives
    /// nil when nothing on disk changed, or whether the change worked.
    private func put(
        _ text: String, at path: String, current: String?, known: String?, report: (Message) -> Void
    ) async -> Bool? {
        let fingerprint = ManagedFile.fingerprint(of: text)
        let source = Paths.macOSTOMLName
        guard current != text else {
            guard known != fingerprint else { return nil }
            report(.adopted(file: path, source: source))
            return remember(path, fingerprint, report: report) ? nil : false
        }
        var message: Message =
            current == nil
            ? (known == nil ? .wrote(path, from: source) : .wroteAgain(path, from: source))
            : .updated(path, from: source)
        if let current, ManagedFile.fingerprint(of: current) != known {
            let backup = path + Self.backupExtension
            guard await asRoot(Install.rootFile(path, to: backup), doing: path, report: report) else { return false }
            let diff = "diff \(Escaping.shell(backup)) \(Escaping.shell(path))"
            message = .overwrote(path, from: source, changed: known != nil, diff: diff)
        }
        guard await install(text, at: path, report: report) else { return false }
        report(message)
        return remember(path, fingerprint, report: report)
    }

    /// Puts back macOS's own `file`, or removes it when macOS has none, and forgets it.
    private func putBack(_ file: SystemFile, report: (Message) -> Void) async -> Bool {
        if let original = file.original {
            guard await install(original, at: file.path, report: report) else { return false }
            report(.putBack(file.path, source: Paths.macOSTOMLName))
        } else {
            guard await asRoot(Remove.file(file.path), doing: file.path, report: report) else { return false }
            report(.removed(file.path, source: Paths.macOSTOMLName))
        }
        return remember(file.path, nil, report: report)
    }

    /// Forgets the file at `path`, which `macos.toml` doesn't set anymore, and leaves it as it is,
    /// saying so when it was `changed` outside Malum. Gives nil, since nothing on disk changed,
    /// unless the record couldn't be changed.
    private func letGo(_ path: String, changed: Bool, report: (Message) -> Void) -> Bool? {
        if changed { report(.keptChanged(path, source: Paths.macOSTOMLName)) }
        return remember(path, nil, report: report) ? nil : false
    }

    /// Stages `text` in the state folder and copies it to `path` as root.
    private func install(_ text: String, at path: String, report: (Message) -> Void) async -> Bool {
        do {
            try state.write(text, to: Self.stagedName)
        } catch {
            report(.failed(.setMacOSSettings, error))
            return false
        }
        let staged = state.path(of: Self.stagedName)
        defer { try? files.remove(staged) }  // A leftover is harmless: the next write replaces it.
        return await asRoot(Install.rootFile(staged, to: path), doing: path, report: report)
    }

    /// Runs `command`, which changes the file at `path`, as root, asking for the password the
    /// first time. Says whether it worked.
    private func asRoot(_ command: Command, doing path: String, report: (Message) -> Void) async -> Bool {
        guard await sudo.authorize(for: .changeSystemFiles, report: report) else { return false }
        let result = await runner.run(Sudo.asRoot(command))
        if !result.succeeded { report(.systemFileNotChanged(path, reason: result.reason)) }
        return result.succeeded
    }

    /// Makes macOS read `/etc/hosts` again, warning when it can't.
    private func rereadHosts(report: (Message) -> Void) async {
        for command in [DSCacheUtil.flush, Killall.hangUp("mDNSResponder")] {
            let result = await runner.run(Sudo.asRoot(command))
            guard result.succeeded else {
                report(.hostsNotReread(reason: result.reason))
                return
            }
        }
    }

    /// Records `fingerprint` as what Malum wrote at `path`, or forgets it when it's nil.
    private func remember(_ path: String, _ fingerprint: String?, report: (Message) -> Void) -> Bool {
        InstalledRecord.remember(in: state, report: report) { $0.systemFiles[path] = fingerprint }
    }
}
