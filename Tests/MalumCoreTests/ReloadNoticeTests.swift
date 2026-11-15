import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ReloadNoticeTests {
    @Test func noErrorsSaysHowManyRestarted() {
        let notice = ReloadNotice(
            messages: [Message(.info, "started launcher"), Message(.warn, "keyboard: unknown key")], running: 3)
        #expect(notice.title == "Malum reloaded")
        #expect(notice.body == "3 modules restarted")
    }

    @Test func errorsGiveTheFirstAndTheCount() {
        let notice = ReloadNotice(
            messages: [Message(.error, "couldn't start samba: boom"), Message(.error, "couldn't start launcher: no")],
            running: 2)
        #expect(notice.title == "Malum couldn't reload everything")
        #expect(notice.body == "couldn't start samba: boom (and 1 more in the log)")
    }
}
