import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct VersionTests {
    @Test func tagAndPlainVersionAreTheSame() {
        #expect(Version("v0.2.0") == Version("0.2.0"))
        #expect(Version("v0.2.0")?.description == "0.2.0")
    }

    @Test(arguments: ["dev", "0.2", "0.2.0.1", "v0.x.0", "", "0..1", "0.-1.0"])
    func otherTextIsNoVersion(text: String) {
        #expect(Version(text) == nil)
    }

    @Test func partsAreComparedAsNumbers() throws {
        let small = try #require(Version("0.9.0"))
        let large = try #require(Version("0.10.0"))
        #expect(small < large)
        #expect(try #require(Version("1.0.0")) > large)
    }
}
