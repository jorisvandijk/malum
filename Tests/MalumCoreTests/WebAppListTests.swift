import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct WebAppListTests {
    @Test func appsAreReadInAlphabeticalOrder() {
        let reading = WebAppList.read(
            """
            [Frigate]
            url = "http://192.168.1.5:5000"
            icon = "icons/frigate.png"

            [Calendar]
            url = "https://calendar.example.com"
            """)
        #expect(
            reading.apps == [
                WebApp(name: "Calendar", url: "https://calendar.example.com", icon: nil),
                WebApp(name: "Frigate", url: "http://192.168.1.5:5000", icon: "icons/frigate.png"),
            ])
        #expect(reading.problems.isEmpty)
    }

    @Test func emptyFileListsNoApps() {
        #expect(WebAppList.read("").apps == [])
    }

    @Test func addressThatIsntWebIsAnErrorAtItsLine() {
        let reading = WebAppList.read("[Frigate]\nurl = \"ftp://nas\"\n")
        #expect(reading.apps == nil)
        #expect(reading.problems.map(\.line) == [2])
    }

    @Test func iconOutsideDotsIsAnError() {
        let reading = WebAppList.read("[Frigate]\nurl = \"https://a.b\"\nicon = \"../frigate.png\"\n")
        #expect(reading.apps == nil)
        #expect(reading.problems.map(\.line) == [3])
    }

    @Test func iconThatIsntAPictureIsAnError() {
        #expect(WebAppList.read("[Frigate]\nurl = \"https://a.b\"\nicon = \"frigate.svg\"\n").apps == nil)
    }

    @Test func nameWithoutLettersIsAnError() {
        #expect(WebAppList.read("[\"--\"]\nurl = \"https://a.b\"\n").apps == nil)
    }

    @Test func unknownKeyIsReported() {
        let reading = WebAppList.read("[Frigate]\nurl = \"https://a.b\"\ncolour = \"red\"\n")
        #expect(reading.problems.map(\.line) == [3])
    }
}
