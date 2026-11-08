import Foundation

/// Writes app config files, and spots changes made to them outside Malum.
///
/// Malum owns every file it writes. A file that was changed since the last run, or that was
/// already there before Malum first wrote it, is overwritten, and the old one is kept next to it,
/// with `.backup` added to its name. A file no app asks for anymore is removed, unless it was
/// changed outside Malum: then it stays, and Malum no longer manages it. A file written only when
/// it's missing is left to its app once it's there, and isn't recorded.
@MainActor
struct AppFileWriter {
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
        guard let record = InstalledRecord.read(from: state, for: .writeAppFiles, report: report) else {
            return false
        }
        var outcomes: [Outcome] = []
        for (app, file) in wanted {
            let path = "\(paths.home)/\(file.path)"
            guard !file.onlyWhenMissing || files.item(at: path) == nil else { continue }
            outcomes.append(write(file, to: path, app: app, known: record.files[path], report: report))
        }
        let wantedPaths = Set(wanted.map { "\(paths.home)/\($0.file.path)" })
        for (path, managed) in record.files.sorted(by: { $0.key < $1.key })
        where !wantedPaths.contains(path) && !keeping.contains(managed.app) {
            outcomes.append(remove(path, managed, report: report))
        }
        if !wanted.isEmpty && outcomes.allSatisfy({ $0 == .unchanged }) {
            report(.appFilesUpToDate)
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
            let current = try files.text(ifFileAt: path)
            guard current != file.text else {
                return adopt(path, app: app, text: file.text, known: known, report: report)
            }
            message = try change(
                at: path, item: item, current: current, known: known, source: Paths.appFile(named: app))
            try files.createDirectory(Self.parent(of: path))
            if case .link = item { try files.remove(path) }
            try files.write(file.text, to: path)
        } catch {
            report(.writeFailed(app: app, error))
            return .failed
        }
        report(message)
        guard !file.onlyWhenMissing else { return .changed }
        return remember(path, ManagedFile(app: app, text: file.text), report: report)
    }

    /// Records the file at `path`, which already holds `text`, when the record doesn't have it yet.
    private func adopt(
        _ path: String, app: String, text: String, known: ManagedFile?, report: (Message) -> Void
    ) -> Outcome {
        let managed = ManagedFile(app: app, text: text)
        guard known != managed else { return .unchanged }
        if known == nil {
            report(.adopted(file: path, source: Paths.appFile(named: app)))
        }
        return remember(path, managed, report: report)
    }

    /// What writing over `current`, the text at `path`, does, keeping the old text first when it
    /// was changed outside Malum.
    private func change(
        at path: String, item: FileItem?, current: String?, known: ManagedFile?, source: String
    ) throws -> Message {
        if case .directory = item { throw FileSystemError.isFolder(path: path) }
        if case .link(let destination) = item {
            return .wrote(path, from: source, replacingLinkTo: destination)
        }
        guard let current else {
            return known == nil ? .wrote(path, from: source) : .wroteAgain(path, from: source)
        }
        guard let known, known.fingerprint == ManagedFile.fingerprint(of: current) else {
            let backup = try backUp(path, current)
            return .overwrote(path, from: source, changed: known != nil, backup: backup)
        }
        return .updated(path, from: source)
    }

    /// Removes the file at `path`, which no app asks for anymore, unless it was changed since
    /// Malum wrote it, and takes it out of the record.
    private func remove(_ path: String, _ managed: ManagedFile, report: (Message) -> Void) -> Outcome {
        guard files.item(at: path) == .file, let current = try? files.read(path) else {  // Unreadable counts as gone.
            return remember(path, nil, report: report)
        }
        guard ManagedFile.fingerprint(of: current) == managed.fingerprint else {
            report(.keptChanged(path, source: Paths.appFile(named: managed.app)))
            return remember(path, nil, report: report)
        }
        do {
            try files.remove(path)
        } catch {
            report(.removeFailed(app: managed.app, error))
            return .failed
        }
        report(.removed(path, source: Paths.appFile(named: managed.app)))
        return remember(path, nil, report: report)
    }

    /// Keeps `text`, the old contents of `path`, next to it, replacing an older copy, and says where.
    private func backUp(_ path: String, _ text: String) throws -> String {
        let backup = ManagedFile.backupPath(of: path)
        try files.write(text, to: backup)
        return backup
    }

    /// Records `managed` as the file at `path`, or takes the path out of the record when it's nil.
    private func remember(_ path: String, _ managed: ManagedFile?, report: (Message) -> Void) -> Outcome {
        let recorded = InstalledRecord.remember(in: state, report: report) { $0.files[path] = managed }
        return recorded ? .changed : .failed
    }

    /// The folder `path` is in.
    private static func parent(of path: String) -> String {
        String(path[..<(path.lastIndex(of: "/") ?? path.endIndex)])
    }
}
