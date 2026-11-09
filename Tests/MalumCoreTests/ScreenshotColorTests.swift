import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotColorTests {
    @Test func hexIsReadInEitherCase() {
        #expect(ScreenshotColor(hex: "#FF3b30") == ScreenshotColor(red: 255, green: 59, blue: 48))
    }

    @Test func notAColorGivesNil() {
        for text in ["ff3b30", "#ff3b3", "#ff3b300", "#gg0000", "#+f0000", "", "#"] {
            #expect(ScreenshotColor(hex: text) == nil)
        }
    }

    @Test func hexIsWrittenLowercaseWithLeadingZeros() {
        #expect(ScreenshotColor(red: 0, green: 10, blue: 255).hex == "#000aff")
    }

    @Test func quickDefaultsAreSevenAndRedFirst() {
        #expect(ScreenshotColor.quickDefaults.count == 7)
        #expect(ScreenshotColor.quickDefaults.first?.hex == "#ff3b30")
        #expect(ScreenshotColor.quickDefaults.last?.hex == "#000000")
    }
}
