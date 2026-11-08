import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct GitHubReleasesTests {
    private let paths = Paths(home: "/Users/test")
    private let state = "/Users/test/Library/Application Support/com.jorisvandijk.malum"
    private let mpv = ReleaseEntry("mpv", repo: "mpv-player/mpv", asset: "mpv-*-arm.zip")
    private let pagefind = ReleaseEntry("pagefind", repo: "CloudCannon/pagefind")

    private var record: String { "\(state)/installed.json" }
    private var downloads: String { "\(state)/downloads" }

    /// The releases in the record of what Malum installed.
    private func installedReleases(_ files: FakeFileSystem) -> [String: InstalledRelease] {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return (try? InstalledRecord.read(from: state).releases) ?? [:]
    }

    /// GitHub with mpv's release `mpvTag` and pagefind's `v1.3.0`.
    private func github(_ files: FakeFileSystem, mpvTag: String = "v0.40.0") -> FakeGitHub {
        FakeGitHub(
            [
                "mpv-player/mpv": Release(
                    tag: mpvTag,
                    assets: [
                        ReleaseAsset(name: "mpv-\(mpvTag)-x86.zip", url: "x86"),
                        ReleaseAsset(name: "mpv-\(mpvTag)-arm.zip", url: "zip"),
                    ]),
                "CloudCannon/pagefind": Release(
                    tag: "v1.3.0",
                    assets: [
                        ReleaseAsset(name: "pagefind-aarch64-apple-darwin.tar.gz", url: "tarball"),
                        ReleaseAsset(name: "pagefind-x86_64-unknown-linux.tar.gz", url: "linux"),
                        ReleaseAsset(name: "checksums.sha256", url: "sums"),
                    ]),
            ], files: files)
    }

    /// A runner whose unpacking puts mpv.app in a zip's folder and the pagefind program in a
    /// tarball's folder.
    private func unpacker(_ files: FakeFileSystem) -> FakeRunner {
        FakeRunner { command in
            guard let folder = command.arguments.last, let archive = command.arguments.dropLast().last else {
                return CommandResult(status: 1)
            }
            if command.executable == Ditto.path {
                try? files.write("app", to: "\(folder)/mpv.app/Contents/Info.plist")
            } else {
                try? files.write("program", to: "\(folder)/pagefind")
                try? files.makeExecutable("\(folder)/pagefind")
            }
            return CommandResult(status: archive.hasSuffix("broken.zip") ? 1 : 0)
        }
    }

    private func run(
        _ entries: [ReleaseEntry], files: FakeFileSystem, github: FakeGitHub? = nil
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let part = GitHubReleases(
            github: github ?? self.github(files), runner: unpacker(files), files: files,
            state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths),
            folders: ReleaseFolders([:], paths: paths))
        let succeeded = await part.run(entries) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func installsAnAppAndAProgramAndRecordsThem() async {
        let files = FakeFileSystem()
        let (succeeded, messages) = await run([mpv, pagefind], files: files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "installing GitHub release mpv v0.40.0 (mpv-v0.40.0-arm.zip)"),
                Message(.info, "installed GitHub release mpv v0.40.0 at /Applications/mpv.app"),
                Message(.info, "installing GitHub release pagefind v1.3.0 (pagefind-aarch64-apple-darwin.tar.gz)"),
                Message(.info, "installed GitHub release pagefind v1.3.0 at /Users/test/.local/bin/pagefind"),
            ])
        #expect(files.text(at: "/Applications/mpv.app/Contents/Info.plist") == "app")
        #expect(files.isExecutable("/Users/test/.local/bin/pagefind"))
        #expect(files.item(at: downloads) == nil)
        #expect(
            installedReleases(files) == [
                "mpv": InstalledRelease(repo: "mpv-player/mpv", tag: "v0.40.0", path: "/Applications/mpv.app"),
                "pagefind": InstalledRelease(
                    repo: "CloudCannon/pagefind", tag: "v1.3.0", path: "/Users/test/.local/bin/pagefind"),
            ])
    }

    @Test func upToDateReleasesAreLeftAlone() async {
        let files = FakeFileSystem()
        _ = await run([mpv], files: files)
        let github = github(files)
        let (succeeded, messages) = await run([mpv], files: files, github: github)
        #expect(succeeded)
        #expect(messages == [Message(.info, "every listed GitHub release is up to date")])
        #expect(github.downloads.isEmpty)
    }

    @Test func newerReleaseReplacesTheOneMalumInstalled() async {
        let files = FakeFileSystem()
        _ = await run([mpv], files: files)
        let (succeeded, messages) = await run([mpv], files: files, github: github(files, mpvTag: "v0.41.0"))
        #expect(succeeded)
        #expect(messages.last == Message(.info, "installed GitHub release mpv v0.41.0 at /Applications/mpv.app"))
        #expect(files.item(at: "/Applications/mpv.app.malum-new") == nil)
        #expect(installedReleases(files)["mpv"]?.tag == "v0.41.0")
    }

    @Test func somethingAlreadyThereIsTakenOver() async {
        let files = FakeFileSystem(texts: ["/Applications/mpv.app/Contents/Info.plist": "mine"])
        let (succeeded, messages) = await run([mpv], files: files)
        #expect(succeeded)
        #expect(
            messages.dropFirst().first
                == Message(.info, "/Applications/mpv.app was already there and was replaced, Malum manages it now"))
        #expect(files.text(at: "/Applications/mpv.app/Contents/Info.plist") == "app")
        #expect(installedReleases(files)["mpv"]?.path == "/Applications/mpv.app")
    }

    @Test func anotherReleaseIsNeverReplaced() async {
        let files = FakeFileSystem()
        let copy = ReleaseEntry("mpv-copy", repo: "mpv-player/mpv", asset: "mpv-*-arm.zip")
        let (succeeded, messages) = await run([mpv, copy], files: files)
        #expect(!succeeded)
        #expect(
            messages.last
                == Message(
                    .error,
                    "couldn't install GitHub release mpv-copy: /Applications/mpv.app is where GitHub release mpv is installed"
                ))
        #expect(installedReleases(files).keys.sorted() == ["mpv"])
    }

    @Test func unlistedReleasesMalumInstalledAreRemoved() async {
        let files = FakeFileSystem()
        _ = await run([mpv, pagefind], files: files)
        let (succeeded, messages) = await run([pagefind], files: files)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "removed GitHub release mpv from /Applications/mpv.app"),
                Message(.info, "every listed GitHub release is up to date"),
            ])
        #expect(files.item(at: "/Applications/mpv.app") == nil)
        #expect(installedReleases(files).keys.sorted() == ["pagefind"])
        let (_, last) = await run([], files: files)
        #expect(last == [Message(.info, "removed GitHub release pagefind from /Users/test/.local/bin/pagefind")])
        #expect(files.item(at: "/Users/test/.local/bin/pagefind") == nil)
        #expect(installedReleases(files).isEmpty)
    }

    @Test func problemsAreReportedAndTheRestGoAhead() async {
        let missing = ReleaseEntry("ghost", repo: "nobody/ghost")
        let down = ReleaseEntry("down", repo: "down/down")
        let files = FakeFileSystem()
        let (succeeded, messages) = await run([down, missing, pagefind], files: files)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't install GitHub release down: GitHub answered with HTTP 503"),
                Message(
                    .error,
                    "couldn't install GitHub release ghost: nobody/ghost has no published release on GitHub, or it's private"
                ),
                Message(.info, "installing GitHub release pagefind v1.3.0 (pagefind-aarch64-apple-darwin.tar.gz)"),
                Message(.info, "installed GitHub release pagefind v1.3.0 at /Users/test/.local/bin/pagefind"),
            ])
    }

    @Test func assetIsPickedByPatternOrForTheMac() throws {
        let release = Release(
            tag: "v1",
            assets: [ReleaseAsset(name: "tool-linux.zip", url: ""), ReleaseAsset(name: "tool-macos.zip", url: "")])
        #expect(try ReleaseFiles.asset(for: ReleaseEntry("tool", repo: "a/tool"), in: release).name == "tool-macos.zip")
        #expect(
            try ReleaseFiles.asset(for: ReleaseEntry("tool", repo: "a/tool", asset: "*-linux.*"), in: release).name
                == "tool-linux.zip")
        #expect(throws: ReleaseError.self) {
            try ReleaseFiles.asset(for: ReleaseEntry("tool", repo: "a/tool", asset: "*.zip"), in: release)
        }
    }

    @Test func installersAreRefused() {
        let release = Release(tag: "v1", assets: [ReleaseAsset(name: "Tool.dmg", url: "")])
        #expect(throws: ReleaseError.self) {
            try ReleaseFiles.asset(for: ReleaseEntry("tool", repo: "a/tool"), in: release)
        }
    }
}
