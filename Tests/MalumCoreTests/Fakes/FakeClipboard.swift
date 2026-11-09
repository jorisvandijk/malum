import Foundation

@testable import MalumCore

/// A clipboard that copies when told, and keeps what was put back and pasted.
@MainActor
final class FakeClipboard: Clipboard {
    var isDenied = false
    /// Whether `put` fails.
    var refusesPut = false
    /// Every entry put back, with its image.
    private(set) var put: [(ClipEntry, Data?)] = []
    /// How often cmd+V was sent.
    private(set) var pastes = 0
    /// Where copies go while watched.
    private var onCopy: (@MainActor (CopySeen) -> Void)?

    var isWatching: Bool { onCopy != nil }

    func watch(_ onCopy: @escaping @MainActor (CopySeen) -> Void) {
        self.onCopy = onCopy
    }

    func stopWatching() {
        onCopy = nil
    }

    func put(_ entry: ClipEntry, image: Data?) -> Bool {
        guard !refusesPut else { return false }
        put.append((entry, image))
        return true
    }

    func paste() {
        pastes += 1
    }

    /// Sends a copy as the real watch would.
    func copy(_ seen: CopySeen) {
        onCopy?(seen)
    }
}
