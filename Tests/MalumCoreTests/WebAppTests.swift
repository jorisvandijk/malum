import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct WebAppTests {
    private let frigate = WebApp(name: "Frigate NVR", url: "http://192.168.1.5:5000", icon: "icons/frigate.png")

    @Test func bundleIDHoldsOnlyTheNamesLettersAndDigits() {
        #expect(frigate.bundleID == "\(Project.bundleID).webapp.frigatenvr")
    }

    @Test func bundleIsNamedAfterTheAppInApplications() {
        #expect(frigate.bundle(Paths(home: "/Users/test")) == "/Users/test/Applications/Frigate NVR.app")
    }

    @Test func infoPlistNamesTheSiteAndTheIcon() throws {
        let plist = frigate.infoPlist(source: "abc")
        #expect(plist.contains("<key>\(WebAppInfo.urlKey)</key><string>http://192.168.1.5:5000</string>"))
        #expect(plist.contains("<key>CFBundleIconFile</key><string>AppIcon</string>"))
        #expect(plist.contains("<key>CFBundleExecutable</key><string>\(WebAppInfo.executable)</string>"))
        #expect(plist.contains("<key>NSAllowsArbitraryLoadsInWebContent</key><true/>"))
        #expect(plist.contains("<key>\(WebAppInfo.sourceKey)</key><string>abc</string>"))
    }

    @Test func infoPlistWithoutIconHasNoIconFile() throws {
        let plain = WebApp(name: "Frigate", url: "https://a.b", icon: nil)
        #expect(plain.infoPlist(source: "abc").contains("CFBundleIconFile") == false)
    }
}
