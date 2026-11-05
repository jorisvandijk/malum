import Foundation

/// Writes app config files, and spots changes made to them outside Malum.
///
/// Malum owns every file it writes. A file that was changed since the last run, or that was
/// already there before Malum first wrote it, is overwritten, and the old one is kept next to it,
/// with `.backup` added to its name. A file no app asks for anymore is removed, unless it was
/// changed outside Malum: then it stays, and Malum no longer manages it.
@MainActor
struct AppFileWriter {
    /// What's added to a file's name for the copy of what was there before Malum overwrote it.
    private static let backupExtension = ".backup"
    /// The characters a path may hold and still be pasted into a shell without quotes.
    private static let shellSafe = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/._-+@:,=")

    /// What writing or removing one file did.
    private enum Outcome {
        /// Nothing needed doing.
        case unchanged
        /// The file or the record changed.
        case changed
        /// It went wrong.
        case failed
    }

    /// The disk.
    private let files: any FileSystem
    /// Where the record is kept.
    private let state: StateFolder
    /// Where the home folder is.
    private let paths: Paths

    /// Creates the writer, which works on `files` and keeps its record in `state`.
    init(files: any FileSystem, state: StateFolder, paths: Paths) {
        self.files = files
        self.state = state
        self.paths = paths
    }

    /// Writes each file in `wanted` for its app, and removes each file Malum wrote that isn't in it,
    /// except those of the apps in `keeping`. Says whether everything worked.
    func write(_ wanted: [(app: String, file: AppFile)], keeping: Set<String>, report: (Message) -> Void) -> Bool {
        let record: InstalledRecord
        do {
            record = try InstalledRecord.read(from: state)
        } catch {
            report(Message(.error, "couldn't write app config files: \(MessageText(error: error))"))
            return false
        }
        var outcomes: [Outcome] = []
        for (app, file) in wanted {
            let path = "\(paths.home)/\(file.path)"
            outcomes.append(write(file, to: path, app: app, known: record.files[path], report: report))
        }
        let wantedPaths = Set(wanted.map { "\(paths.home)/\($0.file.path)" })
        for (path, managed) in record.files.sorted(by: { $0.key < $1.key })
        where !wantedPaths.contains(path) && !keeping.contains(managed.app) {
            outcomes.append(remove(path, managed, report: report))
        }
        if !wanted.isEmpty && outcomes.allSatisfy({ $0 == .unchanged }) {
            report(Message(.info, "every app config file is up to date"))
        }
        return !outcomes.contains(.failed)
    }

    /// Writes `file` to `path` when it isn't right yet, and records it.
    private func write(
        _ file: AppFile, to path: String, app: String, known: ManagedFile?, report: (Message) -> Void
    ) -> Outcome {
        let item = files.item(at: path)
        let message: Message
        do {
            let current = item == .file ? try files.read(path) : nil
            guard current != file.text else {
                return adopt(path, app: app, text: file.text, known: known, report: report)
            }
            message = try change(at: path, item: item, current: current, known: known, source: Self.source(app))
            try files.createDirectory(Self.parent(of: path))
            if case .link = item { try files.remove(path) }
            try files.write(file.text, to: path)
        } catch {
            report(Message(.error, "couldn't write \(app)'s config file: \(MessageText(error: error))"))
            return .failed
        }
        report(message)
        return remember(path, ManagedFile(app: app, text: file.text), report: report)
    }

    /// Records the file at `path`, which already holds `text`, when the record doesn't have it yet.
    private func adopt(
        _ path: String, app: String, text: String, known: ManagedFile?, report: (Message) -> Void
    ) -> Outcome {
        let managed = ManagedFile(app: app, text: text)
        guard known != managed else { return .unchanged }
        if known == nil {
            report(Message(.info, "\(private: path) already matched \(Self.source(app)), Malum manages it now"))
        }
        return remember(path, managed, report: report)
    }

    /// What writing over `current`, the text at `path`, does, keeping the old text first when it
    /// was changed outside Malum.
    private func change(
        at path: String, item: FileItem?, current: String?, known: ManagedFile?, source: String
    ) throws -> Message {
        if case .directory = item { throw FileSystemError.unwritable(path: path, reason: "it's a folder") }
        if case .link(let destination) = item {
            return Message(.info, "wrote \(private: path) from \(source), replacing a link to \(private: destination)")
        }
        guard let current else {
            guard known == nil else {
                return Message(.warn, "\(private: path) was deleted outside Malum, wrote it again from \(source)")
            }
            return Message(.info, "wrote \(private: path) from \(source)")
        }
        guard let known, known.fingerprint == ManagedFile.fingerprint(of: current) else {
            let backup = try backUp(path, current)
            let why =
                known == nil
                ? "was already there and differed from" : "was changed outside Malum, so it was overwritten from"
            let diff = "diff \(Self.shellQuoted(backup)) \(Self.shellQuoted(path))"
            return Message(.warn, "\(private: path) \(why) \(source), see what changed with: \(private: diff)")
        }
        return Message(.info, "updated \(private: path) from \(source)")
    }

    /// Removes the file at `path`, which no app asks for anymore, unless it was changed since
    /// Malum wrote it, and takes it out of the record.
    private func remove(_ path: String, _ managed: ManagedFile, report: (Message) -> Void) -> Outcome {
        guard files.item(at: path) == .file, let current = try? files.read(path) else {
            return remember(path, nil, report: report)
        }
        guard ManagedFile.fingerprint(of: current) == managed.fingerprint else {
            let text: MessageText = """
                \(private: path) isn't written from \(Self.source(managed.app)) anymore, but it was changed \
                outside Malum, so it stays and Malum no longer manages it
                """
            report(Message(.warn, text))
            return remember(path, nil, report: report)
        }
        do {
            try files.remove(path)
        } catch {
            report(Message(.error, "couldn't remove \(managed.app)'s config file: \(MessageText(error: error))"))
            return .failed
        }
        report(Message(.info, "removed \(private: path), \(Self.source(managed.app)) doesn't write it anymore"))
        return remember(path, nil, report: report)
    }

    /// Keeps `text`, the old contents of `path`, next to it, replacing an older copy, and says where.
    private func backUp(_ path: String, _ text: String) throws -> String {
        let backup = path + Self.backupExtension
        try files.write(text, to: backup)
        return backup
    }

    /// `path` as it's pasted into a shell: as it is when that's safe, in single quotes otherwise.
    private static func shellQuoted(_ path: String) -> String {
        guard !path.allSatisfy(shellSafe.contains) else { return path }
        return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Records `managed` as the file at `path`, or takes the path out of the record when it's nil.
    private func remember(_ path: String, _ managed: ManagedFile?, report: (Message) -> Void) -> Outcome {
        do {
            try InstalledRecord.change(in: state) { $0.files[path] = managed }
            return .changed
        } catch {
            report(Message(.error, "couldn't record what Malum wrote: \(MessageText(error: error))"))
            return .failed
        }
    }

    /// `apps/<app>.toml`, where an app's files come from.
    private static func source(_ app: String) -> String {
        "\(Paths.appsFolderName)/\(app).toml"
    }

    /// The folder `path` is in.
    private static func parent(of path: String) -> String {
        String(path[..<(path.lastIndex(of: "/") ?? path.endIndex)])
    }
}
