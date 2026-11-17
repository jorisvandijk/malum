import Foundation

/// MarkEdit's extensions and themes, listed in `apps/markedit.toml`: installs each listed one from
/// MarkEdit's registry into its scripts folder, updates it when the registry has a newer version,
/// and removes each one Malum installed that isn't listed anymore. MarkEdit runs every script in
/// the folder, so a listed extension is also an enabled one.
@MainActor
struct MarkEditExtensions {
    /// What installing one extension did.
    private enum Outcome {
        /// It was already at the registry's version.
        case unchanged
        /// It was installed or updated.
        case installed
        /// It went wrong.
        case failed
    }

    /// The registry MarkEdit's Extensions window installs from.
    private static let registry = "https://raw.githubusercontent.com/MarkEdit-app/extensions/main/index.json"
    /// The state folder's folder downloads go in, removed after each run.
    private static let downloadsName = "markedit-downloads"
    /// The registry's file, in the downloads folder.
    private static let indexName = "index.json"
    /// What a script's file has after the extension's id, which is how MarkEdit names it too.
    private static let scriptExtension = ".js"

    /// Downloads the registry and the scripts.
    let github: any GitHub
    /// Runs `shasum`, to check each download against the registry.
    let runner: any CommandRunner
    /// The disk.
    let files: any FileSystem
    /// Where the record of what Malum installed is kept.
    let state: StateFolder
    /// MarkEdit's scripts folder.
    let scripts: String

    /// Whether `id` can be an extension's id: letters, digits and dashes, which also makes it a
    /// safe file name.
    nonisolated static func isID(_ id: String) -> Bool {
        !id.isEmpty && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
    }

    /// Installs or updates the extensions in `ids`, and removes the ones Malum installed that
    /// aren't in it, reporting each step as it goes. Says whether everything worked.
    func run(_ ids: [String], report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: .installMarkEditExtensions, report: report) else {
            return false
        }
        let managed = record.markEditExtensions
        guard !ids.isEmpty || !managed.isEmpty else { return true }
        var succeeded = true
        for id in managed.keys.sorted() where !ids.contains(id) {
            succeeded = remove(id, report: report) && succeeded
        }
        guard !ids.isEmpty else { return succeeded }
        let scratch = state.path(of: Self.downloadsName)
        defer { try? files.remove(scratch) }  // Best effort: the next run clears it first.
        guard let index = await index(in: scratch, report: report) else { return false }
        var changed = false
        for id in ids {
            switch await update(id, to: index[id], from: managed[id], in: scratch, report: report) {
            case .unchanged:
                continue
            case .installed:
                changed = true
            case .failed:
                succeeded = false
            }
        }
        if succeeded && !changed { report(.markEditExtensionsUpToDate) }
        return succeeded
    }

    /// The registry's latest release of each extension, by id, or nil after reporting why it
    /// couldn't be read.
    private func index(in scratch: String, report: (Message) -> Void) async -> [String: MarkEditRelease]? {
        let path = "\(scratch)/\(Self.indexName)"
        do {
            try? files.remove(scratch)  // A leftover from an earlier run; usually there's none.
            try files.createDirectory(scratch)
            try await github.download(ReleaseAsset(name: Self.indexName, url: Self.registry), to: path)
            return try MarkEditRelease.index(from: files.data(at: path))
        } catch {
            report(.failed(.readMarkEditRegistry, error))
            return nil
        }
    }

    /// Installs `release`, the registry's latest of the extension `id`, unless `installed`, the
    /// version Malum installed, is that already.
    private func update(
        _ id: String, to release: MarkEditRelease?, from installed: String?, in scratch: String,
        report: (Message) -> Void
    ) async -> Outcome {
        let path = script(id)
        do {
            guard let release else { throw MarkEditError.unknown(id: id) }
            guard installed != release.version || files.item(at: path) == nil else { return .unchanged }
            let download = "\(scratch)/\(id)\(Self.scriptExtension)"
            try await github.download(ReleaseAsset(name: id, url: release.url), to: download)
            let checksum = await runner.run(Shasum.sha256(download))
            guard checksum.succeeded, Shasum.checksum(in: checksum.output) == release.sha256.lowercased() else {
                throw MarkEditError.checksum(id: id)
            }
            try files.createDirectory(scripts)
            if files.item(at: path) != nil { try files.remove(path) }
            try files.copy(download, to: path)
            guard InstalledRecord.remember(in: state, report: report, { $0.markEditExtensions[id] = release.version })
            else { return .failed }
            report(.installed(markEditExtension: id, version: release.version))
            return .installed
        } catch {
            report(.installFailed(markEditExtension: id, error))
            return .failed
        }
    }

    /// Removes the script of `id`, which isn't listed anymore, and takes it out of the record.
    private func remove(_ id: String, report: (Message) -> Void) -> Bool {
        let path = script(id)
        do {
            if files.item(at: path) != nil { try files.remove(path) }
        } catch {
            report(.removeFailed(markEditExtension: id, error))
            return false
        }
        report(.removed(markEditExtension: id))
        return InstalledRecord.remember(in: state, report: report) { $0.markEditExtensions[id] = nil }
    }

    /// The script of the extension `id`.
    private func script(_ id: String) -> String {
        "\(scripts)/\(id)\(Self.scriptExtension)"
    }
}
