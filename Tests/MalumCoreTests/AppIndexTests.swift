import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppIndexTests {
    private let paths = Paths(home: "/Users/test")

    private func plist(_ bundleID: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict><key>CFBundleIdentifier</key><string>\(bundleID)</string></dict></plist>
        """
    }

    private func apps(_ files: FakeFileSystem) -> [LaunchableApp] {
        AppIndex(files: files).apps(in: AppFolder.standard(paths: paths))
    }

    @Test func appsAreFoundSortedByName() {
        let files = FakeFileSystem(texts: [
            "/Applications/kitty.app/Contents/Info.plist": plist("net.kovidgoyal.kitty"),
            "/System/Applications/Mail.app/Contents/Info.plist": plist("com.apple.mail"),
            "/System/Library/CoreServices/Finder.app/Contents/Info.plist": plist("com.apple.finder"),
            "/System/Library/CoreServices/Dock.app/Contents/Info.plist": plist("com.apple.dock"),
        ])
        #expect(apps(files).map(\.name) == ["Finder", "kitty", "Mail"])
        #expect(apps(files).first?.bundleID == "com.apple.finder")
    }

    @Test func subfoldersAreSearchedTwoDeep() {
        let files = FakeFileSystem(texts: [
            "/Applications/Utilities/Tools/Deep.app/Contents/Info.plist": plist("a.deep"),
            "/Applications/Utilities/Tools/More/Deeper.app/Contents/Info.plist": plist("a.deeper"),
        ])
        #expect(apps(files).map(\.name) == ["Deep"])
    }

    @Test func linkedAppsAreFollowed() {
        let files = FakeFileSystem(
            items: [
                "/Users/test/Applications/Nix Apps/mpv.app": .link(to: "/nix/store/mpv.app"),
                "/nix/store/mpv.app": .directory,
            ],
            spellings: ["/Users/test/Applications/Nix Apps/mpv.app": "/nix/store/mpv.app"])
        #expect(apps(files).map(\.path) == ["/Users/test/Applications/Nix Apps/mpv.app"])
        #expect(apps(files).first?.key == "/Users/test/Applications/Nix Apps/mpv.app")
    }

    @Test func sameBundleIDKeepsTheFirstFolder() {
        let files = FakeFileSystem(texts: [
            "/Applications/Safari.app/Contents/Info.plist": plist("com.apple.Safari"),
            "/Users/test/Applications/Safari.app/Contents/Info.plist": plist("com.apple.Safari"),
        ])
        #expect(apps(files).map(\.path) == ["/Applications/Safari.app"])
    }

    @Test func hiddenAndPlainFilesAreSkipped() {
        let files = FakeFileSystem(texts: [
            "/Applications/.Hidden.app/Contents/Info.plist": plist("a.hidden"),
            "/Applications/notes.app": "not a bundle",
        ])
        #expect(apps(files).isEmpty)
    }

    @Test func missingFoldersHaveNoApps() {
        #expect(apps(FakeFileSystem()).isEmpty)
    }
}
