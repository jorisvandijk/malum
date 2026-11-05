import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct MessageTests {
    @Test func descriptionStartsWithLowercaseTag() {
        #expect(
            Message(.warn, "couldn't read malum.toml: no such file").description
                == "[warn] couldn't read malum.toml: no such file")
    }
}

@Suite(.timeLimit(.minutes(1)))
struct MessageShapesTests {
    @Test func couldntPutsTheReasonAfterTheAction() {
        #expect(Message.couldnt("read \(private: "/a")", "gone").description == "[error] couldn't read /a: gone")
    }

    @Test func couldntKeepsTheActionPrivatePartsPrivate() {
        #expect(Message.couldnt("read \(private: "/a")", "gone").text.redacted == "couldn't read <private>: gone")
    }

    @Test func failedWithAnActionAddsTheErrorText() {
        let error = FileSystemError.unreadable(path: "/a", reason: "gone")
        #expect(Message.failed("load", error).description == "[error] couldn't load: couldn't read /a: gone")
    }

    @Test func failedAloneGivesTheErrorText() {
        let error = FileSystemError.unreadable(path: "/a", reason: "gone")
        #expect(Message.failed(error).description == "[error] couldn't read /a: gone")
    }

    @Test func managesNowNamesTheProject() {
        #expect(MessageText.managesNow("x was there").description == "x was there, \(Project.name) manages it now")
    }
}
