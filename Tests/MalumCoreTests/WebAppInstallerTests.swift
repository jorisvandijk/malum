import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct WebAppInstallerTests {
    private let paths = Paths(home: "/Users/test")
    private let dots = "/Users/test/dots"
    private let bundle = "/Users/test/Applications/Frigate.app"
    private let list = "[Frigate]\nurl = \"http://192.168.1.5:5000\"\nicon = \"icons/frigate.png\"\n"
    private let runner = FakeRunner { command in
        guard command.arguments.first == "find-identity" else { return CommandResult(status: 0) }
        return CommandResult(status: 0, output: SigningCertificateTests.listed)
    }

    /// A disk with the web app executable, the icon and `texts`.
    private func disk(_ texts: [String: String]) -> FakeFileSystem {
        FakeFileSystem(
            texts: texts.merging([paths.webAppExecutable: "executable", "\(dots)/icons/frigate.png": "png"]) { $1 })
    }

    /// Runs the installer on `files`, giving whether it worked and what it said.
    private func run(_ files: FakeFileSystem) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let installer = WebAppInstaller(
            files: files, runner: runner, paths: paths,
            state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths),
            certificate: SigningCertificate(runner: runner, files: files, paths: paths, temporaryDirectory: "/tmp"))
        let worked = await installer.run(dots: dots) { messages.append($0) }
        return (worked, messages)
    }

    /// An app bundle with the bundle ID `id`.
    private func app(_ id: String) -> String {
        "<plist><dict><key>CFBundleIdentifier</key><string>\(id)</string></dict></plist>"
    }

    @Test func listedAppIsMadeSignedWithItsIcon() async throws {
        let files = disk(["\(dots)/webapps.toml": list])
        let (worked, messages) = await run(files)
        #expect(worked)
        #expect(messages == [.madeWebApp("Frigate")])
        let plist = try #require(files.text(at: "\(bundle)/Contents/Info.plist"))
        #expect(plist.contains("http://192.168.1.5:5000"))
        #expect(files.text(at: "\(bundle)/Contents/MacOS/\(WebAppInfo.executable)") == "executable")
        #expect(runner.commands.contains { $0.executable == Sips.path })
        #expect(runner.commands.contains { $0.arguments.first == "--force" })
        #expect(!files.allPaths.contains { $0.hasPrefix(paths.stateDirectory) && $0.contains("Frigate.app") })
    }

    @Test func unchangedAppIsLeftAlone() async {
        let files = disk(["\(dots)/webapps.toml": list])
        _ = await run(files)
        let signings = runner.commands.count
        let (worked, messages) = await run(files)
        #expect(worked)
        #expect(messages.isEmpty)
        #expect(runner.commands.count == signings + 1)  // Only looking for the certificate.
    }

    @Test func changedSiteBuildsTheAppAgain() async {
        let files = disk(["\(dots)/webapps.toml": list])
        _ = await run(files)
        try? files.write(list.replacingOccurrences(of: "5000", with: "5001"), to: "\(dots)/webapps.toml")
        let (worked, messages) = await run(files)
        #expect(worked)
        #expect(messages == [.updatedWebApp("Frigate")])
    }

    @Test func unlistedWebAppIsRemovedAndOtherAppsStay() async {
        let old = "/Users/test/Applications/Calendar.app"
        let other = "/Users/test/Applications/Kitty.app"
        let files = disk([
            "\(old)/Contents/Info.plist": app("\(WebApp.bundleIDPrefix)calendar"),
            "\(other)/Contents/Info.plist": app("net.kovidgoyal.kitty"),
        ])
        let (worked, messages) = await run(files)
        #expect(worked)
        #expect(messages == [.removedWebApp("Calendar")])
        #expect(files.item(at: old) == nil)
        #expect(files.item(at: other) != nil)
    }

    @Test func otherAppInTheWayIsLeftAndReported() async {
        let files = disk(["\(dots)/webapps.toml": list, "\(bundle)/Contents/Info.plist": app("com.frigate.app")])
        let (worked, messages) = await run(files)
        #expect(!worked)
        #expect(messages.first?.level == .error)
        #expect(files.text(at: "\(bundle)/Contents/Info.plist") == app("com.frigate.app"))
    }

    @Test func missingExecutableIsAnError() async {
        let files = FakeFileSystem(texts: ["\(dots)/webapps.toml": list])
        let (worked, messages) = await run(files)
        #expect(!worked)
        #expect(messages == [.noWebAppExecutable(paths.webAppExecutable)])
    }

    @Test func noFileMakesNothing() async {
        let (worked, messages) = await run(disk([:]))
        #expect(worked)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }
}
