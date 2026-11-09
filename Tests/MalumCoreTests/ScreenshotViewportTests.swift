import Foundation
import Testing

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotViewportTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)

    @Test func theWholeShotAtRealSizeMapsEachPointToItself() {
        let viewport = ScreenshotViewport(screen: screen)
        let point = CGPoint(x: 123, y: 456)
        #expect(viewport.shown == screen)
        #expect(viewport.shotPoint(at: point) == point && viewport.overlayPoint(at: point) == point)
    }

    @Test func aCropIsCenteredAtRealSize() {
        var viewport = ScreenshotViewport(screen: screen)
        viewport.show(CGRect(x: 0, y: 0, width: 200, height: 100))
        #expect(viewport.shown == CGRect(x: 400, y: 250, width: 200, height: 100))
        #expect(viewport.shotPoint(at: CGPoint(x: 400, y: 250)) == .zero)
        #expect(viewport.overlayPoint(at: CGPoint(x: 200, y: 100)) == CGPoint(x: 600, y: 350))
    }

    @Test func zoomKeepsThePointUnderTheAnchor() {
        var viewport = ScreenshotViewport(screen: screen)
        let anchor = CGPoint(x: 250, y: 150)
        let held = viewport.shotPoint(at: anchor)
        viewport.zoom(by: 2, at: anchor)
        #expect(viewport.scale == 2)
        #expect(viewport.shotPoint(at: anchor) == held)
        #expect(viewport.shown.width == 2000)
    }

    @Test func zoomStaysWithinItsLimits() {
        var viewport = ScreenshotViewport(screen: screen)
        viewport.zoom(by: 100, at: .zero)
        #expect(viewport.scale == ScreenshotViewport.maxScale)
        viewport.zoom(by: 0.0001, at: .zero)
        #expect(viewport.scale == ScreenshotViewport.minScale)
    }

    @Test func stepsZoomAroundTheMiddleAndResetGoesBack() {
        var viewport = ScreenshotViewport(screen: screen)
        viewport.zoomIn()
        #expect(viewport.scale > 1 && viewport.shotPoint(at: CGPoint(x: 500, y: 300)) == CGPoint(x: 500, y: 300))
        viewport.zoomOut()
        #expect(abs(viewport.scale - 1) < 1e-9)
        viewport.move(by: CGPoint(x: 30, y: -20))
        #expect(viewport.shotPoint(at: CGPoint(x: 30, y: -20)) == .zero)
        viewport.reset()
        #expect(viewport.shown == screen)
    }

    @Test func showingANewCropResetsZoomAndPan() {
        var viewport = ScreenshotViewport(screen: screen)
        viewport.zoomIn()
        viewport.move(by: CGPoint(x: 10, y: 10))
        viewport.show(screen)
        #expect(viewport == ScreenshotViewport(screen: screen))
    }
}
