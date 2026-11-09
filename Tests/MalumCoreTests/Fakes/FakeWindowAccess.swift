import Foundation

@testable import MalumCore

/// Accessibility as the test sets it.
@MainActor
final class FakeWindowAccess: WindowAccess {
    /// The apps it watches, by process ID.
    var apps: [Int32: FakeWatchedApp] = [:]
    var isPointerDown = false

    func watch(_ pid: Int32, onChange: @escaping @MainActor (WindowEvent) -> Void) -> (any WatchedApp)? {
        apps[pid]
    }
}
