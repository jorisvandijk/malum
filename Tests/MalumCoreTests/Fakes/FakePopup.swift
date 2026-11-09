@testable import MalumCore

/// A popup that keeps what it was asked to show.
@MainActor
final class FakePopup: Popup {
    var isOpen = false
    var onEvent: (@MainActor (PopupEvent) -> Void)?
    /// Every content it was given, opening or showing.
    var shown: [PopupContent] = []
    /// How often it was opened.
    var opened = 0

    func open(_ content: PopupContent) {
        isOpen = true
        opened += 1
        shown.append(content)
    }

    func show(_ content: PopupContent) {
        shown.append(content)
    }

    func close() {
        isOpen = false
    }

    /// Sends `event` as the panel would.
    func send(_ event: PopupEvent) {
        onEvent?(event)
    }
}
