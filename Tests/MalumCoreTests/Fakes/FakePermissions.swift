import Synchronization

@testable import MalumCore

/// Grants every permission except the ones it's told are missing or unknown.
final class FakePermissions: PermissionCheck {
    /// The state of each permission that isn't granted.
    private let states: Mutex<[Permission: PermissionState]>

    init(_ states: [Permission: PermissionState] = [:]) {
        self.states = Mutex(states)
    }

    /// Changes the state of `permission`, as the user does in System Settings.
    func set(_ permission: Permission, _ state: PermissionState) {
        states.withLock { $0[permission] = state }
    }

    func state(of permission: Permission) -> PermissionState {
        states.withLock { $0[permission] ?? .granted }
    }
}
