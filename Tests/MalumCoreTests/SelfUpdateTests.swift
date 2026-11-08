import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SelfUpdateTests {
    private let paths = Paths(home: "/Users/test")
    private let listed = "  1) \(SigningCertificateTests.hash) \"Malum code signing\"\n"
    private let zip = "Malum-macos-arm64.zip"

    private var installedInfo: String { "\(paths.installedBundle)/Contents/Info.plist" }
    private var keptInfo: String { "\(paths.previousBundle)/Contents/Info.plist" }
    private var scratch: String { "\(paths.stateDirectory)/update" }

    /// The installed app at `version`, with `kept` as the version kept for a rollback.
    private func disk(installed version: String = "0.2.0", kept: String? = nil) -> FakeFileSystem {
        var texts = [installedInfo: AppBundleTests.info(version: version)]
        if let kept { texts[keptInfo] = AppBundleTests.info(version: kept) }
        return FakeFileSystem(texts: texts)
    }

    /// GitHub whose latest release of Malum is `tag`, with a checksum file that says `sum`.
    private func github(_ files: FakeFileSystem, tag: String = "v0.3.0", sum: String = "abc123") -> FakeGitHub {
        FakeGitHub(
            [
                Project.repository: Release(
                    tag: tag,
                    assets: [
                        ReleaseAsset(name: zip, url: "zip"),
                        ReleaseAsset(name: "\(zip).sha256", url: "\(sum)  \(zip)\n"),
                    ])
            ], files: files)
    }

    /// A runner whose unzip puts an app of version `version` in the folder, whose apps have the
    /// bundle ID `bundleID`, and whose downloaded app says it's `says`. Every other tool works.
    private func runner(
        _ files: FakeFileSystem, version: String = "0.3.0", bundleID: String = Project.bundleID,
        says: String = "0.3.0"
    ) -> FakeRunner {
        let listed = listed
        return FakeRunner { command in
            switch command.executable {
            case Shasum.path:
                return CommandResult(status: 0, output: "abc123  \(command.arguments.last ?? "")\n")
            case Ditto.path:
                let info = AppBundleTests.info(bundleID: bundleID, version: version)
                try? files.write(info, to: "\(command.arguments.last ?? "")/Malum.app/Contents/Info.plist")
                return CommandResult(status: 0)
            case let path where path.hasSuffix("/Contents/MacOS/Malum"):
                return CommandResult(status: 0, output: "\(says)\n")
            default:
                return CommandResult(status: 0, output: listed)
            }
        }
    }

    private func update(
        _ files: FakeFileSystem, github: (any GitHub)? = nil, runner: FakeRunner? = nil,
        executable: String? = nil, current: String = "0.2.0"
    ) -> SelfUpdate {
        let runner = runner ?? self.runner(files)
        return SelfUpdate(
            github: github ?? self.github(files), runner: runner, files: files, paths: paths,
            state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths),
            certificate: SigningCertificate(runner: runner, files: files, paths: paths, temporaryDirectory: "/tmp"),
            executable: executable ?? paths.installedExecutable, current: current, userID: 501)
    }

    private func run(_ update: SelfUpdate, force: Bool = false) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let succeeded = await update.run(force: force) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func buildFolderDoesNotUpdate() async {
        let files = disk()
        let github = github(files)
        let runner = runner(files)
        let built = "/Users/test/Git/malum/build/Malum.app/Contents/MacOS/Malum"
        let (succeeded, messages) = await run(update(files, github: github, runner: runner, executable: built))
        #expect(succeeded)
        #expect(
            messages == [Message(.info, "not updating: Malum isn't running from /Users/test/Applications/Malum.app")])
        #expect(runner.commands.isEmpty && github.downloads.isEmpty)
    }

    @Test func devBuildDoesNotUpdate() async {
        let files = disk()
        let runner = runner(files)
        let (succeeded, messages) = await run(update(files, runner: runner, current: "dev"))
        #expect(succeeded)
        #expect(messages == [Message(.info, "not updating: this is a dev build of Malum, not a release")])
        #expect(runner.commands.isEmpty)
    }

    @Test func latestReleaseIsUpToDate() async {
        let files = disk()
        let (succeeded, messages) = await run(update(files, github: github(files, tag: "v0.2.0")))
        #expect(succeeded)
        #expect(messages == [Message(.info, "Malum 0.2.0 is up to date")])
    }

    @Test func olderReleaseWaitsForForce() async {
        let files = disk()
        let github = github(files, tag: "v0.1.0")
        let (succeeded, messages) = await run(update(files, github: github))
        #expect(succeeded)
        #expect(
            messages == [
                Message(
                    .warn, "the latest release, 0.1.0, is older than Malum 0.2.0; run malum run --force to install it")
            ])
        #expect(github.downloads.isEmpty)
    }

    @Test func newerReleaseIsCheckedSignedSwappedInAndRestarted() async {
        let files = disk()
        let runner = runner(files)
        let (succeeded, messages) = await run(update(files, runner: runner))
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "updating Malum 0.2.0 to 0.3.0"),
                Message(.info, "updated Malum to 0.3.0; malum rollback puts 0.2.0 back"),
            ])
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.3.0"))
        #expect(files.text(at: keptInfo) == AppBundleTests.info(version: "0.2.0"))
        #expect(files.item(at: scratch) == nil)
        let app = "\(scratch)/unpacked/Malum.app"
        #expect(
            runner.commands.map(\.executable) == [
                Shasum.path, Ditto.path, "/usr/bin/security", Codesign.path, Codesign.path,
                "\(app)/Contents/MacOS/Malum", "/bin/launchctl", "/bin/launchctl",
            ])
        #expect(runner.commands.first { $0.arguments.first == "--force" }?.arguments.last == "\(app).staged")
    }

    @Test func forceInstallsAnOlderRelease() async {
        let files = disk()
        let update = update(
            files, github: github(files, tag: "v0.1.0"), runner: runner(files, version: "0.1.0", says: "0.1.0"))
        let (succeeded, messages) = await run(update, force: true)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "updating Malum 0.2.0 to 0.1.0"),
                Message(.info, "updated Malum to 0.1.0; malum rollback puts 0.2.0 back"),
            ])
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.1.0"))
    }

    @Test func privateRepositoryIsReported() async {
        let files = disk()
        let (succeeded, messages) = await run(update(files, github: FakeGitHub([:], files: files)))
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't update Malum: \(Project.repository) has no published release on GitHub, or it's private")
            ])
    }

    @Test func missingTokenIsReported() async {
        let files = disk()
        let github = FailingGitHub(error: .needsToken(repo: Project.repository))
        let (succeeded, messages) = await run(update(files, github: github))
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't update Malum: GitHub shows \(Project.repository) only with a token, run malum token")
            ])
    }

    @Test func wrongChecksumLeavesTheAppAlone() async {
        let files = disk()
        let (succeeded, messages) = await run(update(files, github: github(files, sum: "fff000")))
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't update Malum: \(zip) doesn't match its checksum"))
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.2.0"))
        #expect(files.item(at: keptInfo) == nil && files.item(at: scratch) == nil)
    }

    @Test func otherAppLeavesTheAppAlone() async {
        let files = disk()
        let (succeeded, messages) = await run(update(files, runner: runner(files, bundleID: "com.example.other")))
        #expect(!succeeded)
        #expect(
            messages.last
                == Message(
                    .error, "couldn't update Malum: the downloaded app is com.example.other, not \(Project.bundleID)"
                ))
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.2.0"))
    }

    @Test func wrongVersionLeavesTheAppAlone() async {
        let files = disk()
        let (succeeded, messages) = await run(update(files, runner: runner(files, says: "0.2.9")))
        #expect(!succeeded)
        #expect(
            messages.last == Message(.error, "couldn't update Malum: the downloaded app says it's 0.2.9, not 0.3.0"))
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.2.0"))
    }

    @Test func rollbackSwapsTheKeptVersionInBothWays() async {
        let files = disk(installed: "0.3.0", kept: "0.2.0")
        var messages: [Message] = []
        #expect(await update(files).rollBack { messages.append($0) })
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.2.0"))
        #expect(files.text(at: keptInfo) == AppBundleTests.info(version: "0.3.0"))
        #expect(await update(files).rollBack { messages.append($0) })
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.3.0"))
        #expect(files.text(at: keptInfo) == AppBundleTests.info(version: "0.2.0"))
        #expect(
            messages == [
                Message(.info, "rolled back Malum to 0.2.0; malum rollback puts 0.3.0 back"),
                Message(.info, "rolled back Malum to 0.3.0; malum rollback puts 0.2.0 back"),
            ])
    }

    @Test func rollbackWithNothingKeptFails() async {
        let files = disk()
        var messages: [Message] = []
        #expect(!(await update(files).rollBack { messages.append($0) }))
        #expect(messages == [Message(.error, "couldn't roll back Malum: no previous version is kept")])
        #expect(files.text(at: installedInfo) == AppBundleTests.info(version: "0.2.0"))
    }
}

/// GitHub that answers every lookup with `error`.
private struct FailingGitHub: GitHub {
    /// What every call throws.
    let error: GitHubError

    func latestRelease(of repo: String) async throws(GitHubError) -> Release? { throw error }

    func download(_ asset: ReleaseAsset, to path: String) async throws(GitHubError) { throw error }

    func check(_ token: String, canRead repo: String) async throws(GitHubError) { throw error }
}
