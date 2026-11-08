import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppBundleTests {
    private static let bundle = "/Applications/GarageBand.app"

    /// An `Info.plist` in XML with the bundle ID `bundleID` and the version `version`.
    static func info(bundleID: String = Project.bundleID, version: String) -> String {
        """
        \(PlistText.header)
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>\(bundleID)</string>
            <key>CFBundleShortVersionString</key>
            <string>\(version)</string>
        </dict>
        </plist>

        """
    }

    @Test func executableInsideAppIsFound() {
        let path = "/Users/test/Applications/Malum.app/Contents/MacOS/Malum"
        #expect(AppBundle.executable(at: path) == path)
    }

    @Test func buildFolderIsNotAnApp() {
        #expect(AppBundle.executable(at: "/Users/test/git/malum/.build/debug/Malum") == nil)
    }

    @Test func appWithoutContentsIsNotAnApp() {
        #expect(AppBundle.executable(at: "/Users/test/Applications/Malum.app/MacOS/Malum") == nil)
    }

    @Test func readsTheBundleIDAndVersion() {
        let text = Self.info(bundleID: "com.apple.garageband10", version: "10.4.12")
        let files = FakeFileSystem(texts: ["\(Self.bundle)/Contents/Info.plist": text])
        #expect(AppBundle.bundleID(of: Self.bundle, files: files) == "com.apple.garageband10")
        #expect(AppBundle.version(of: Self.bundle, files: files) == "10.4.12")
    }

    @Test func missingOrBrokenInfoGivesNothing() {
        #expect(AppBundle.bundleID(of: Self.bundle, files: FakeFileSystem()) == nil)
        let files = FakeFileSystem(texts: ["\(Self.bundle)/Contents/Info.plist": "not a plist"])
        #expect(AppBundle.version(of: Self.bundle, files: files) == nil)
    }

    @Test func readsABinaryInfo() throws {
        let files = LocalFileSystem()
        let bundle = NSTemporaryDirectory() + "malum-tests-\(UUID().uuidString).app"
        defer { try? files.remove(bundle) }
        try files.createDirectory("\(bundle)/Contents")
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": "com.apple.Pages"], format: .binary, options: 0)
        try data.write(to: URL(fileURLWithPath: "\(bundle)/Contents/Info.plist"))
        #expect(AppBundle.bundleID(of: bundle, files: files) == "com.apple.Pages")
        #expect(AppBundle.version(of: bundle, files: files) == nil)
    }
}
