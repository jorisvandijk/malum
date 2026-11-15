import Foundation

@testable import MalumCore

/// Accessibility as the test sets it.
@MainActor
final class FakeWindowAccess: WindowAccess {
    /// The apps it watches, by process ID.
    var apps: [Int32: FakeWatchedApp] = [:]
    var isPointerDown = false
    var pointerLocation = CGPoint.zero
    /// The window at every point.
    var pointed: PointedWindow?
    /// Every point a window was looked for at.
    private(set) var lookedAt: [CGPoint] = []

    func watch(_ pid: Int32, onChange: @escaping @MainActor (WindowEvent) -> Void) -> (any WatchedApp)? {
        apps[pid]
    }

    func window(at point: CGPoint) -> PointedWindow? {
        lookedAt.append(point)
        return pointed
    }
}
