import Foundation

/// Updates the installed Malum to its latest release during `malum run`, and puts the version it
/// replaced back with `malum rollback`.
///
/// A release is swapped in only after its checksum, bundle ID, signature and version all check out,
/// and only signed with Malum's own certificate, so every permission survives. When a check fails,
/// the installed app stays as it is.
@MainActor
public struct SelfUpdate {
    /// The state folder's folder the download is unpacked in, removed after each update.
    private static let scratchName = "update"
    /// The release's file that holds the app.
    static let assetName = "\(Project.name)-macos-arm64.zip"
    /// What the checksum file adds to the asset's name.
    private static let checksumExtension = ".sha256"

    /// Looks up and downloads the releases.
    private let github: any GitHub
    /// Runs the tools that check and sign the download.
    private let runner: any CommandRunner
    /// The disk.
    private let files: any FileSystem
    /// Where the installed app and the kept one are.
    private let paths: Paths
    /// Where the download is unpacked.
    private let state: StateFolder
    /// Malum's certificate in the login keychain.
    private let certificate: SigningCertificate
    /// The running executable with its links resolved, or nil outside an app bundle.
    private let executable: String?
    /// The running version, such as `0.2.0`, or `dev` for a build that isn't a release.
    private let current: String
    /// The user whose login agent is restarted.
    private let userID: UInt32

    /// Creates the update of the app at `paths`, which only runs when `executable` is the installed
    /// one at version `current`, and restarts it for the user `userID`.
    public init(
        github: any GitHub, runner: any CommandRunner, files: any FileSystem, paths: Paths, state: StateFolder,
        certificate: SigningCertificate, executable: String?, current: String, userID: UInt32
    ) {
        self.github = github
        self.runner = runner
        self.files = files
        self.paths = paths
        self.state = state
        self.certificate = certificate
        self.executable = executable
        self.current = current
        self.userID = userID
    }

    /// Signs and restarts the app.
    private var signing: SelfSigning {
        SelfSigning(runner: runner, files: files, paths: paths, certificate: certificate)
    }

    /// Installs the latest release when it's newer than the running version, or older with `force`,
    /// keeps the one it replaced and restarts the app, reporting as it goes. Says whether it worked;
    /// having nothing to do counts.
    public func run(force: Bool, report: (Message) -> Void) async -> Bool {
        guard paths.isInstalled(executable: executable, files: files) else {
            report(.noSelfUpdate(notInstalled: paths.installedBundle))
            return true
        }
        guard let running = Version(current) else {
            report(.noSelfUpdate(build: current))
            return true
        }
        do {
            guard let latest = try await github.latestRelease(of: Project.repository) else {
                throw ReleaseError.noRelease(repo: Project.repository)
            }
            guard let version = Version(latest.tag) else { throw UpdateError.unreadableTag(latest.tag) }
            guard version != running else {
                report(.upToDate(running))
                return true
            }
            guard version > running || force else {
                report(.releaseIsOlder(latest: version, running: running))
                return true
            }
            report(.updating(from: running, to: version))
            try await install(latest, version: version, report: report)
            report(.updated(to: version, kept: running))
        } catch {
            report(.failed(.updateApp, error))
            return false
        }
        await restart(report: report)
        return true
    }

    /// Swaps the installed app with the kept one, so a second rollback goes forward again, and
    /// restarts it, reporting as it goes. Says whether it worked.
    public func rollBack(report: (Message) -> Void) async -> Bool {
        let installed = files.canonicalPath(paths.installedBundle)
        let kept = paths.previousBundle
        do {
            guard files.item(at: kept) != nil else { throw UpdateError.nothingKept }
            guard let identity = await certificate.find() else { throw UpdateError.noCertificate }
            guard await BundleSigner(runner: runner, files: files).isSigned(kept, by: identity) else {
                throw UpdateError.keptUnsigned
            }
            let from = version(of: installed)
            let back = version(of: kept)
            try files.exchange(kept, installed)
            report(.rolledBack(to: back, kept: from))
        } catch {
            report(.failed(.rollBackApp, error))
            return false
        }
        await restart(report: report)
        return true
    }

    /// Downloads and checks `release`, swaps it in for the installed app, and keeps the app it
    /// replaced.
    private func install(_ release: Release, version: Version, report: (Message) -> Void) async throws {
        let scratch = state.path(of: Self.scratchName)
        try? files.remove(scratch)  // A leftover from an interrupted update; usually there's none.
        try files.createDirectory(scratch)
        defer { try? files.remove(scratch) }  // Best effort: the next update clears it first.
        let app = try await download(release, into: scratch)
        try await check(app, version: version)
        try files.exchange(app, files.canonicalPath(paths.installedBundle))
        keep(app, report: report)
    }

    /// Downloads the release's zip into `scratch`, checks it against its checksum, and unpacks it.
    /// Gives back the app in it.
    private func download(_ release: Release, into scratch: String) async throws -> String {
        let zip = try asset(Self.assetName, in: release)
        let sum = try asset(Self.assetName + Self.checksumExtension, in: release)
        let zipPath = "\(scratch)/\(zip.name)"
        let sumPath = "\(scratch)/\(sum.name)"
        try await github.download(zip, to: zipPath)
        try await github.download(sum, to: sumPath)
        let computed = await runner.run(Shasum.sha256(zipPath))
        guard computed.succeeded else { throw UpdateError.uncheckable(reason: computed.reason) }
        guard let expected = Shasum.checksum(in: try files.read(sumPath)),
            Shasum.checksum(in: computed.output) == expected
        else { throw UpdateError.checksumMismatch(name: zip.name) }
        let folder = "\(scratch)/unpacked"
        try files.createDirectory(folder)
        let unzipped = await runner.run(Ditto.unzip(zipPath, into: folder))
        guard unzipped.succeeded else { throw UpdateError.unpackable(reason: unzipped.reason) }
        let app = "\(folder)/\(Project.name).app"
        guard files.item(at: app) == .directory else { throw UpdateError.noApp(name: zip.name) }
        return app
    }

    /// Checks that `app` is Malum, signs it with Malum's certificate, and checks that it says it's
    /// `version`.
    private func check(_ app: String, version: Version) async throws {
        let bundleID = AppBundle.bundleID(of: app, files: files)
        guard bundleID == Project.bundleID else { throw UpdateError.otherApp(bundleID: bundleID) }
        guard let identity = await certificate.find() else { throw UpdateError.noCertificate }
        try await BundleSigner(runner: runner, files: files).install(app, at: app, identity: identity)
        let answer = await runner.run(AppVersion.ask(Paths.executable(in: app)))
        let said = answer.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard answer.succeeded, said == version.description else {
            throw UpdateError.wrongVersion(
                expected: version.description, found: answer.succeeded ? said : answer.reason)
        }
    }

    /// Moves the replaced app, now at `old`, to the kept place, over the one kept before. An update
    /// that can't keep it still counts, so this only warns.
    private func keep(_ old: String, report: (Message) -> Void) {
        let kept = paths.previousBundle
        do {
            if files.item(at: kept) != nil { try files.remove(kept) }
            try files.createDirectory((kept as NSString).deletingLastPathComponent)
            try files.copy(old, to: kept)
        } catch {
            report(.previousNotKept(error))
        }
    }

    /// The file of `release` called `name`.
    private func asset(_ name: String, in release: Release) throws(UpdateError) -> ReleaseAsset {
        guard let found = release.assets.first(where: { $0.name == name }) else {
            throw .missingAsset(name: name, tag: release.tag)
        }
        return found
    }

    /// The version the app `bundle` says it is, as its `Info.plist` has it.
    private func version(of bundle: String) -> String {
        AppBundle.version(of: bundle, files: files) ?? Self.unknownVersion
    }

    /// Restarts the app so the swapped-in version runs. The new version is in place either way, so
    /// a failure only warns.
    private func restart(report: (Message) -> Void) async {
        do {
            try await signing.restart(userID: userID)
        } catch {
            report(.warning(error))
        }
    }
}
