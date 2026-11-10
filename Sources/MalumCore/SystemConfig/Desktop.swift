/// The desktop picture of every screen, as macOS keeps it.
@MainActor
public protocol Desktop {
    /// The path of the picture each screen shows now, nil for a screen that shows none.
    func pictures() -> [String?]

    /// Shows the picture at `path` on every screen.
    func show(_ path: String) throws
}
