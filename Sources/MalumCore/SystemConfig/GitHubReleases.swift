import Foundation

/// The GitHub releases part of system config: installs each listed release that isn't installed
/// yet, and updates each one Malum installed when a newer release is out.
@MainActor
public struct GitHubReleases {
    /// The state folder's folder that downloads are unpacked in, removed after each one.
    private static let downloadsName = "downloads"
    /// How many archives deep a download is unpacked, so a zip that holds a tarball also works.
    private static let unpackLevels = 2

    /// Looks up and downloads releases.
    private let github: any GitHub
    /// Runs the unpacking tools.
    private let runner: any CommandRunner
    /// The disk.
    private let files: any FileSystem
    /// Where the record of what Malum installed is kept.
    private let state: StateFolder
    /// Where apps and programs go.
    private let folders: ReleaseFolders

    /// Creates the part, which gets releases from `github`, unpacks them with `runner` on `files`,
    /// installs them into `folders` and keeps its record in `state`.
    public init(
        github: any GitHub, runner: any CommandRunner, files: any FileSystem, state: StateFolder,
        folders: ReleaseFolders
    ) {
        self.github = github
        self.runner = runner
        self.files = files
        self.state = state
        self.folders = folders
    }

    /// Installs or updates each release in `releases`, reporting each step as it goes. Says whether
    /// every one is installed and up to date now.
    public func run(_ releases: [ReleaseEntry], report: (Message) -> Void) async -> Bool {
        guard !releases.isEmpty else { return true }
        var succeeded = true
        var changed = false
        for entry in releases {
            do {
                let record = InstalledRelease.record(from: try state.read(InstalledRelease.recordName))
                guard let installed = try await update(entry, previous: record[entry.name], report: report) else {
                    continue
                }
                try state.update(InstalledRelease.recordName) { text in
                    InstalledRelease.text(
                        of: InstalledRelease.record(from: text).merging([entry.name: installed]) { $1 })
                }
                report(
                    Message(
                        .info, "installed GitHub release \(entry.name) \(installed.tag) at \(private: installed.path)"))
                changed = true
            } catch {
                let reason = (error as? any ReportableError)?.text ?? MessageText(String(describing: error))
                report(Message(.error, "couldn't install GitHub release \(entry.name): \(reason)"))
                succeeded = false
            }
        }
        if succeeded && !changed { report(Message(.info, "every listed GitHub release is up to date")) }
        return succeeded
    }

    /// Installs the latest release of `entry`, unless `previous` is it already. Gives back what it
    /// installed, or nil when nothing changed.
    private func update(
        _ entry: ReleaseEntry, previous: InstalledRelease?, report: (Message) -> Void
    ) async throws -> InstalledRelease? {
        guard let latest = try await github.latestRelease(of: entry.repo) else {
            throw ReleaseError("\(entry.repo) has no published release on GitHub, or it's private")
        }
        if let previous, previous.repo == entry.repo, previous.tag == latest.tag, files.item(at: previous.path) != nil {
            return nil
        }
        let asset = try ReleaseFiles.asset(for: entry, in: latest)
        report(Message(.info, "installing GitHub release \(entry.name) \(latest.tag) (\(asset.name))"))
        let scratch = state.path(of: Self.downloadsName)
        try? files.remove(scratch)
        try files.createDirectory(scratch)
        defer { try? files.remove(scratch) }
        let download = "\(scratch)/\(asset.name)"
        try await github.download(asset, to: download)
        let (payload, isApp) = try await unpack(download, name: entry.name, in: scratch)
        let destination =
            isApp ? "\(folders.apps)/\((payload as NSString).lastPathComponent)" : "\(folders.programs)/\(entry.name)"
        try place(payload, at: destination, previous: previous?.path)
        if !isApp { try files.makeExecutable(destination) }
        return InstalledRelease(repo: entry.repo, tag: latest.tag, path: destination)
    }

    /// What to install from the downloaded file `download`: the file itself, or what's in it once
    /// it's unpacked, along with one archive inside it. Says whether it's an app.
    private func unpack(_ download: String, name: String, in scratch: String) async throws -> (String, Bool) {
        var archive = download
        for level in 1...Self.unpackLevels {
            guard ReleaseFiles.ends(archive, with: ReleaseFiles.tarballs + [ReleaseFiles.zip]) else { break }
            let folder = "\(scratch)/unpacked\(level)"
            try files.createDirectory(folder)
            let isZip = ReleaseFiles.ends(archive, with: [ReleaseFiles.zip])
            let result = await runner.run(
                isZip ? Ditto.unzip(archive, into: folder) : Tar.unpack(archive, into: folder))
            guard result.succeeded else { throw ReleaseError("couldn't unpack \(private: archive): \(result.reason)") }
            let found = try ReleaseFiles.contents(of: folder, files: files)
            guard found.apps.isEmpty, found.programs.isEmpty, found.archives.count == 1 else {
                return try ReleaseFiles.payload(in: found, name: name)
            }
            archive = found.archives[0]
        }
        guard archive == download else { throw ReleaseError("it holds archives inside archives") }
        return (download, false)
    }

    /// Puts `payload` at `destination`, replacing what's there only when Malum put it there, which
    /// `previous` says. Removes `previous` when the new one goes elsewhere.
    private func place(_ payload: String, at destination: String, previous: String?) throws {
        try files.createDirectory((destination as NSString).deletingLastPathComponent)
        if files.item(at: destination) == nil {
            try files.copy(payload, to: destination)
        } else {
            guard previous == destination else {
                throw ReleaseError("\(private: destination) is already there, and Malum didn't install it")
            }
            let staged = "\(destination).\(Project.command)-new"
            try? files.remove(staged)
            try files.copy(payload, to: staged)
            try files.exchange(destination, staged)
            try files.remove(staged)
        }
        guard let previous, previous != destination, files.item(at: previous) != nil else { return }
        try files.remove(previous)
    }
}
