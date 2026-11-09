import Foundation

/// The system clipboard, for the clipboard history. `PasteboardClipboard` in MalumPlatform is the
/// real one.
@MainActor
public protocol Clipboard: AnyObject {
    /// Whether macOS's Paste from Other Apps setting denies Malum the clipboard.
    var isDenied: Bool { get }
    /// Starts looking for copies, calling `onCopy` with each one. macOS has no event for a copy, so
    /// it looks a few times a second, reading only after the clipboard changed.
    func watch(_ onCopy: @escaping @MainActor (CopySeen) -> Void)
    /// Stops looking.
    func stopWatching()
    /// Puts `entry` back on the clipboard, with `image` as its PNG for an image entry, without
    /// seeing it as a new copy. Says whether it worked.
    func put(_ entry: ClipEntry, image: Data?) -> Bool
    /// Sends cmd+V to the front app, once the popup is gone.
    func paste()
}
