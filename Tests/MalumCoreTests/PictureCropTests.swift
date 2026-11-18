import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PictureCropTests {
    @Test func macOSRectangleIsRead() {
        #expect(
            PictureCrop("{{117, 190.5}, {827, 827}}") == PictureCrop(left: 117, bottom: 190.5, width: 827, height: 827))
    }

    @Test func textWithoutFourNumbersIsNoCrop() {
        #expect(PictureCrop("{{117, 190}}") == nil)
    }
}
