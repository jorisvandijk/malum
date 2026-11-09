/// The popup window that `PopupCenter` drives. `PopupPanel` in MalumPlatform is the real one.
@MainActor
public protocol Popup: AnyObject {
    /// Whether it's on screen.
    var isOpen: Bool { get }
    /// Where it sends what happens in it.
    var onEvent: (@MainActor (PopupEvent) -> Void)? { get set }
    /// Shows it in the middle of the screen with an empty search field, taking the typing
    /// without making Malum the active app.
    func open(_ content: PopupContent)
    /// Shows new rows or another selection while it's open, keeping the search text.
    func show(_ content: PopupContent)
    /// Takes it off screen.
    func close()
}
