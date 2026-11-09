import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct WindowLayoutTests {
    /// A 1512x982 screen below a 25 point menu bar.
    private let area = CGRect(x: 0, y: 25, width: 1512, height: 957)
    private let standard = WindowFacts(role: "AXWindow", subrole: "AXStandardWindow", title: "Main")
    private let floats = [
        FloatRule(app: "com.apple.SecurityAgent", title: nil),
        FloatRule(app: "org.gimp.gimp", title: "^(Open|Export)"),
    ]

    @Test func oneWindowFillsTheArea() {
        #expect(WindowLayout.slots(count: 1, in: area) == [area])
        #expect(WindowLayout.slots(count: 0, in: area).isEmpty)
    }

    @Test func twoWindowsSplitLeftAndRight() {
        #expect(
            WindowLayout.slots(count: 2, in: area) == [
                CGRect(x: 0, y: 25, width: 756, height: 957), CGRect(x: 756, y: 25, width: 756, height: 957),
            ])
    }

    @Test func moreWindowsStackOnTheRight() {
        #expect(
            WindowLayout.slots(count: 4, in: area) == [
                CGRect(x: 0, y: 25, width: 756, height: 957),
                CGRect(x: 756, y: 25, width: 756, height: 319),
                CGRect(x: 756, y: 344, width: 756, height: 319),
                CGRect(x: 756, y: 663, width: 756, height: 319),
            ])
    }

    @Test func oddWidthLeavesNoGap() {
        let slots = WindowLayout.slots(count: 2, in: CGRect(x: 0, y: 0, width: 1001, height: 500))
        #expect(slots.first?.maxX == slots.last?.minX)
        #expect(slots.last?.maxX == 1001)
    }

    @Test func smallWindowIsCentredAndLargeOneIsPinned() {
        let slot = CGRect(x: 0, y: 25, width: 1000, height: 800)
        #expect(WindowLayout.place(CGSize(width: 600, height: 400), in: slot) == CGPoint(x: 200, y: 225))
        #expect(WindowLayout.place(CGSize(width: 1200, height: 800), in: slot) == CGPoint(x: 0, y: 25))
    }

    @Test func accessibilityFramesStartAtTheTop() {
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 957)
        #expect(WindowLayout.toAccessibility(visible, mainScreenHeight: 982) == area)
    }

    @Test func framesWithinAPointAreTheSame() {
        #expect(WindowLayout.isSame(area, area.offsetBy(dx: 1, dy: -1)))
        #expect(!WindowLayout.isSame(area, area.insetBy(dx: 2, dy: 0)))
    }

    @Test func dropLandsOnAnotherWindowsSlot() {
        let slots = WindowLayout.slots(count: 3, in: area)
        #expect(WindowLayout.dropTarget(at: CGPoint(x: 900, y: 800), slots: slots, from: 0) == 2)
        #expect(WindowLayout.dropTarget(at: CGPoint(x: 100, y: 100), slots: slots, from: 0) == nil)
        #expect(WindowLayout.dropTarget(at: CGPoint(x: 100, y: 1000), slots: slots, from: 1) == nil)
    }

    @Test func standardWindowIsManaged() {
        #expect(WindowLayout.classify(standard, app: "net.kovidgoyal.kitty", floats: floats) == .managed)
    }

    @Test func dialogsModalsFixedSizeAndFullscreenFloat() {
        var dialog = standard
        dialog.subrole = "AXDialog"
        #expect(WindowLayout.classify(dialog, app: nil, floats: []) == .float(.subrole("AXDialog")))
        var modal = standard
        modal.isModal = true
        #expect(WindowLayout.classify(modal, app: nil, floats: []) == .float(.modal))
        var fixed = standard
        fixed.isResizable = false
        #expect(WindowLayout.classify(fixed, app: nil, floats: []) == .float(.fixedSize))
        var fullScreen = standard
        fullScreen.isFullScreen = true
        #expect(WindowLayout.classify(fullScreen, app: nil, floats: []) == .float(.fullScreen))
        var sheet = standard
        sheet.role = "AXSheet"
        #expect(WindowLayout.classify(sheet, app: nil, floats: []) == .float(.role("AXSheet")))
    }

    @Test func windowThatDoesNotSayWhatItIsIsNotReady() {
        var early = standard
        early.subrole = "AXUnknown"
        #expect(WindowLayout.classify(early, app: nil, floats: []) == .notReady)
        early.subrole = nil
        #expect(WindowLayout.classify(early, app: nil, floats: []) == .notReady)
        early.role = nil
        #expect(WindowLayout.classify(early, app: nil, floats: []) == .notReady)
    }

    @Test func floatRulesMatchTheAppAndTheTitle() {
        #expect(WindowLayout.classify(standard, app: "com.apple.SecurityAgent", floats: floats) == .float(.rule))
        var export = standard
        export.title = "Export Image"
        #expect(WindowLayout.classify(export, app: "org.gimp.gimp", floats: floats) == .float(.rule))
        #expect(WindowLayout.classify(standard, app: "org.gimp.gimp", floats: floats) == .managed)
        var untitled = standard
        untitled.title = nil
        #expect(WindowLayout.classify(untitled, app: "org.gimp.gimp", floats: floats) == .managed)
    }
}
