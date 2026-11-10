/// The Mac's own screen, as macOS shows it.
@MainActor
public protocol Display {
    /// The size the screen shows things at now, nil when it's off, such as with the lid closed.
    func resolution() -> DisplayResolution?

    /// Shows the screen at `resolution` from now on, after a restart too.
    func show(_ resolution: DisplayResolution) throws
}
