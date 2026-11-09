import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct LauncherModuleTests {
    private let paths = Paths(home: "/Users/test")
    private let popup = FakePopup()
    private let folders = FakeFolderWatch()
    private let apps = FakeAppControl()
    private let routes = ModuleRoutes()
    private let files: FakeFileSystem

    init() {
        files = FakeFileSystem(texts: [
            "/Applications/kitty.app/Contents/Info.plist": Self.plist("net.kovidgoyal.kitty"),
            "/System/Applications/Mail.app/Contents/Info.plist": Self.plist("com.apple.mail"),
        ])
    }

    private static func plist(_ bundleID: String) -> String {
        "<plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>\(bundleID)</string></dict></plist>"
    }

    private func started() async throws -> LauncherModule {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let system = LauncherSystem(
            files: files, paths: paths, state: state, apps: apps, folders: folders,
            popup: PopupCenter(popup: popup))
        let module = LauncherModule(system: system, routes: routes, log: Log(writer: RecordingLogWriter()))
        try await module.start()
        return module
    }

    private var titles: [String] {
        popup.shown.last?.rows.map(\.title) ?? []
    }

    @Test func offersTheLauncherAction() async throws {
        #expect(try await started().hotkeys == HotkeyOffer(actions: ["launcher"]))
    }

    @Test func actionOpensThePopupOnEveryApp() async throws {
        let module = try await started()
        module.perform(.module("launcher"))
        #expect(popup.isOpen)
        #expect(titles == ["kitty", "Mail"])
        #expect(popup.shown.last?.rows.first?.icon == .file("/Applications/kitty.app"))
    }

    @Test func pickingAnAppOpensItAndCountsIt() async throws {
        let module = try await started()
        module.perform(.module("launcher"))
        popup.send(.clicked(1))
        await module.opening?.value
        #expect(apps.calls == ["open com.apple.mail"])
        #expect(
            try LaunchCounts(state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths)).read()
                == ["com.apple.mail": 1])
    }

    @Test func appsStartedMoreComeFirstAmongEqualMatches() async throws {
        let module = try await started()
        module.perform(.module("launcher"))
        popup.send(.clicked(1))
        module.perform(.module("launcher"))
        popup.send(.query("a"))
        #expect(titles.first == "Mail")
    }

    @Test func runningWindowManagerOpensThePickedApp() async throws {
        let manager = RecordingModule(id: "window_manager")
        manager.hotkeys = HotkeyOffer(opensApps: true)
        try await manager.start()
        routes.add([manager])
        let module = try await started()
        module.perform(.module("launcher"))
        popup.send(.clicked(0))
        #expect(manager.calls.last == "perform \(KeyAction.app("net.kovidgoyal.kitty"))")
        #expect(apps.calls.isEmpty)
    }

    @Test func newAppsShowAfterAFolderChange() async throws {
        let module = try await started()
        #expect(folders.folders.contains("/Applications"))
        module.perform(.module("launcher"))
        try files.write(Self.plist("org.gimp.gimp"), to: "/Applications/GIMP.app/Contents/Info.plist")
        folders.change()
        #expect(titles == ["GIMP", "kitty", "Mail"])
    }

    @Test func stopTakesTheListAwayAndStopsWatching() async throws {
        let module = try await started()
        module.perform(.module("launcher"))
        await module.stop()
        #expect(!popup.isOpen)
        #expect(folders.folders.isEmpty)
        #expect(module.status == .off)
    }
}
