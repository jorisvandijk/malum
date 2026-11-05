import Foundation

/// The GitHub releases part of system config: installs each listed release that isn't installed
/// yet, updates each one Malum installed when a newer release is out, and removes each one Malum
/// installed that isn't listed anymore.
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

    /// Installs or updates each release in `releases`, and removes each one Malum installed that
    /// isn't listed anymore, reporting each step as it goes. Says whether everything worked.
    public func run(_ releases: [ReleaseEntry], report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: .installReleases, report: report) else {
            return false
        }
        let listed = Set(releases.map(\.name))
        var succeeded = true
        for (name, installed) in record.releases.sorted(by: { $0.key < $1.key }) where !listed.contains(name) {
            succeeded = remove(name, installed, report: report) && succeeded
        }
        guard !releases.isEmpty else { return succeeded }
        var changed = false
        var recorded = record.releases
        for entry in releases {
            do {
                guard let installed = try await update(entry, recorded: recorded, report: report) else { continue }
                guard InstalledRecord.remember(in: state, report: report, { $0.releases[entry.name] = installed })
                else {
                    succeeded = false
                    continue
                }
                recorded[entry.name] = installed
                report(.installed(release: entry.name, tag: installed.tag, at: installed.path))
                changed = true
            } catch {
                report(.installFailed(release: entry.name, error))
                succeeded = false
            }
        }
        if succeeded && !changed { report(.releasesUpToDate) }
        return succeeded
    }

    /// Removes the release `name` that Malum installed, and takes it out of the record. Says whether
    /// it worked.
    private func remove(_ name: String, _ installed: InstalledRelease, report: (Message) -> Void) -> Bool {
        do {
            if files.item(at: installed.path) != nil { try files.remove(installed.path) }
        } catch {
            report(.removeFailed(release: name, error))
            return false
        }
        guard InstalledRecord.remember(in: state, report: report, { $0.releases[name] = nil }) else { return false }
        report(.removed(release: name, from: installed.path))
        return true
    }

    /// Installs the latest release of `entry`, unless what `recorded` holds for it is that already.
    /// Gives back what it installed, or nil when nothing changed.
    private func update(
        _ entry: ReleaseEntry, recorded: [String: InstalledRelease], report: (Message) -> Void
    ) async throws -> InstalledRelease? {
        let previous = recorded[entry.name]
        guard let latest = try await github.latestRelease(of: entry.repo) else {
            throw ReleaseError.noRelease(repo: entry.repo)
        }
        if let previous, previous.repo == entry.repo, previous.tag == latest.tag, files.item(at: previous.path) != nil {
            return nil
        }
        let asset = try ReleaseFiles.asset(for: entry, in: latest)
        report(.installing(release: entry.name, tag: latest.tag, asset: asset.name))
        let scratch = state.path(of: Self.downloadsName)
        try? files.remove(scratch)  // A leftover from an earlier run; usually there's none.
        try files.createDirectory(scratch)
        defer { try? files.remove(scratch) }  // Best effort: the next download clears it first.
        let download = "\(scratch)/\(asset.name)"
        try await github.download(asset, to: download)
        let (payload, isApp) = try await unpack(download, name: entry.name, in: scratch)
        let destination =
            isApp ? "\(folders.apps)/\((payload as NSString).lastPathComponent)" : "\(folders.programs)/\(entry.name)"
        let owner = recorded.first { $0.key != entry.name && $0.value.path == destination }?.key
        try place(payload, at: destination, previous: previous?.path, owner: owner, report: report)
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
            guard result.succeeded else { throw ReleaseError.unpackable(path: archive, reason: result.reason) }
            let found = try ReleaseFiles.contents(of: folder, files: files)
            guard found.apps.isEmpty, found.programs.isEmpty, found.archives.count == 1,
                let inner = found.archives.first
            else { return try ReleaseFiles.payload(in: found, name: name) }
            archive = inner
        }
        guard archive == download else { throw ReleaseError.nestedArchives }
        return (download, false)
    }

    /// Puts `payload` at `destination`, replacing what's there and taking it over, unless the release
    /// `owner` is installed there. Removes `previous` when the new one goes elsewhere.
    private func place(
        _ payload: String, at destination: String, previous: String?, owner: String?, report: (Message) -> Void
    ) throws {
        try files.createDirectory((destination as NSString).deletingLastPathComponent)
        if files.item(at: destination) == nil {
            try files.copy(payload, to: destination)
        } else {
            if let owner { throw ReleaseError.taken(path: destination, by: owner) }
            let staged = "\(destination).\(Project.command)-new"
            try? files.remove(staged)  // A leftover from an interrupted update; usually there's none.
            try files.copy(payload, to: staged)
            try files.replace(destination, with: staged)
            if previous != destination { report(.takenOver(release: destination)) }
        }
        guard let previous, previous != destination, files.item(at: previous) != nil else { return }
        try files.remove(previous)
    }
}
