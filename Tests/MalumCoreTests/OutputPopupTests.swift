import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct OutputPopupTests {
    private let popup = FakePopup()

    private var titles: [String] {
        popup.shown.last?.rows.map(\.title) ?? []
    }

    @Test func runShowsEachLineAsItComesNewestFirst() async {
        let output = OutputPopup(center: PopupCenter(popup: popup))
        await output.run("malum run") { write in
            write("[info] one")
            #expect(titles == ["[info] one"])
            write("[warn] two")
        }
        #expect(popup.isOpen)
        #expect(popup.shown.last?.label == "malum run")
        #expect(titles == ["[warn] two", "[info] one"])
        #expect(!output.isRunning)
    }

    @Test func aNewRunStartsEmpty() async {
        let output = OutputPopup(center: PopupCenter(popup: popup))
        await output.run("malum run") { write in write("old") }
        await output.run("log, last hour") { write in write("new") }
        #expect(popup.shown.last?.label == "log, last hour")
        #expect(titles == ["new"])
    }

    @Test func aSecondRunWhileOneGoesOnlyShowsThePopup() async {
        let output = OutputPopup(center: PopupCenter(popup: popup))
        await output.run("malum run") { write in
            write("first")
            await output.run("log, last hour") { again in again("second") }
        }
        #expect(titles == ["first"])
    }

    @Test func searchKeepsTheLinesHoldingIt() async {
        let output = OutputPopup(center: PopupCenter(popup: popup))
        await output.run("malum run") { write in
            write("[info] Brew done")
            write("[warn] zsh skipped")
        }
        popup.send(.query("BREW"))
        #expect(titles == ["[info] Brew done"])
    }

    @Test func tabDoesntReachTheOutput() async {
        let center = PopupCenter(popup: popup)
        let output = OutputPopup(center: center)
        center.register(FakePopupSource("Apps", names: ["Mail"]), as: "launcher")
        await output.run("malum run") { write in write("line") }
        center.toggle("launcher")
        popup.send(.command(.switchList))
        #expect(popup.shown.last?.label == "Apps")
    }
}
