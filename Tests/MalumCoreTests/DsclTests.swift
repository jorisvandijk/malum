import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct DsclTests {
    @Test func pictureOnItsOwnLineIsRead() {
        #expect(
            Dscl.picture(in: "Picture:\n /Library/User Pictures/Eagle.heic\n") == "/Library/User Pictures/Eagle.heic")
    }

    @Test func pictureOnTheSameLineIsRead() {
        #expect(Dscl.picture(in: "Picture: /tmp/a.png\n") == "/tmp/a.png")
    }

    @Test func otherOutputNamesNoPicture() {
        #expect(Dscl.picture(in: "No such key: Picture\n") == nil)
    }

    @Test func readNamesTheUsersRecord() {
        #expect(Dscl.readPicture(of: "test").arguments == [".", "-read", "/Users/test", "Picture"])
    }
}
