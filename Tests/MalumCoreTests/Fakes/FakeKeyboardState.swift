@testable import MalumCore

/// The keyboard state a test sets.
@MainActor
final class FakeKeyboardState: KeyboardState {
    var secureInput = SecureInput.off
    var modifierSwaps: [[String: UInt64]] = []
}
