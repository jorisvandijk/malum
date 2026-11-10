import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct DisplaySettingsTests {
    private static let moreSpace = DisplayResolution(width: 1710, height: 1112)
    private static let standard = DisplayResolution(width: 1470, height: 956)

    /// Reads `toml` as `macos.toml`, and gives back the size it sets and every problem.
    private func read(_ toml: String) -> (DisplayResolution?, [Message]) {
        let (wanted, problems) = MacOSSettings.read(toml)
        return (wanted?.resolution, problems.map(\.message))
    }

    /// Sets `wanted` on `display`, and gives back whether it worked and what it said.
    private func set(_ wanted: DisplayResolution?, on display: FakeDisplay) -> (Bool, [Message]) {
        var messages: [Message] = []
        let succeeded = DisplaySettings(display: display).set(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func readsTheResolution() {
        let (resolution, problems) = read("[display]\nresolution = \"1710x1112\"\n")
        #expect(problems.isEmpty)
        #expect(resolution == Self.moreSpace)
    }

    @Test func noDisplayTableSetsNothing() {
        let (resolution, problems) = read("[computer]\nboot_sound = false\n")
        #expect(problems.isEmpty)
        #expect(resolution == nil)
    }

    @Test(arguments: ["1710", "1710x", "0x1112", "1710 x 1112", "1710x1112x2"])
    func malformedResolutionReportsLine(text: String) {
        let (resolution, problems) = read("[display]\nresolution = \"\(text)\"\n")
        #expect(resolution == nil)
        #expect(
            problems == [
                Message(
                    .error,
                    """
                    macos.toml line 2: display.resolution: a resolution is the width and height in points, such as \
                    "1710x1112"
                    """)
            ])
    }

    @Test func resolutionThatIsntTextReportsLine() {
        let (_, problems) = read("[display]\nresolution = 1710\n")
        #expect(problems == [Message(.error, "macos.toml line 2: display.resolution should be text in quotes")])
    }

    @Test func unknownKeyReportsLine() {
        let (_, problems) = read("[display]\nscale = 2\n")
        #expect(problems == [Message(.warn, "macos.toml line 2: unknown setting display.scale")])
    }

    @Test func otherResolutionIsSwitched() {
        let display = FakeDisplay(shown: Self.standard)
        let (succeeded, messages) = set(Self.moreSpace, on: display)
        #expect(succeeded)
        #expect(display.shown == Self.moreSpace)
        #expect(
            messages == [Message(.info, "set the screen's resolution to 1710x1112 from macos.toml (it was 1470x956)")])
    }

    @Test func sameResolutionStaysQuiet() {
        let display = FakeDisplay(shown: Self.moreSpace, failure: .refused(code: 1000))
        let (succeeded, messages) = set(Self.moreSpace, on: display)
        #expect(succeeded)
        #expect(messages.isEmpty)
    }

    @Test func noResolutionLeavesTheScreen() {
        let display = FakeDisplay(shown: Self.standard, failure: .refused(code: 1000))
        let (succeeded, messages) = set(nil, on: display)
        #expect(succeeded)
        #expect(messages.isEmpty)
    }

    @Test func screenOffIsSkipped() {
        let (succeeded, messages) = set(Self.moreSpace, on: FakeDisplay(shown: nil))
        #expect(succeeded)
        #expect(messages == [Message(.info, "the Mac's own screen is off, so [display] in macos.toml was skipped")])
    }

    @Test func unavailableResolutionListsTheOffered() {
        let failure = DisplayError.unavailable(Self.moreSpace, offered: [Self.standard, Self.moreSpace].sorted())
        let display = FakeDisplay(shown: Self.standard, failure: failure)
        let (succeeded, messages) = set(DisplayResolution(width: 1800, height: 1169), on: display)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    """
                    couldn't set the screen's resolution: the screen can't show 1710x1112, it can show 1470x956, \
                    1710x1112
                    """)
            ])
    }
}
