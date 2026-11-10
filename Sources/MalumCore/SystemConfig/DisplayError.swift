/// Why the Mac's own screen couldn't be set to a size.
public enum DisplayError: Error, Equatable, Sendable {
    /// The screen is off, such as with the lid closed.
    case noScreen
    /// The screen can't show this size; it can show the sizes `offered`.
    case unavailable(DisplayResolution, offered: [DisplayResolution])
    /// macOS turned the change down with this CoreGraphics error code.
    case refused(code: Int32)
}
