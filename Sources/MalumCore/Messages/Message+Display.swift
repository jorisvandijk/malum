/// The words for `[display]` in `macos.toml`.
extension MessageText {
    /// Setting the size the Mac's own screen shows things at.
    static let setResolution: MessageText = "set the screen's resolution"
}

extension Message {
    /// The Mac's own screen shows things at `resolution` now; it was `was`.
    static func resolutionSet(_ resolution: DisplayResolution, was: DisplayResolution) -> Message {
        Message(.info, "set the screen's resolution to \(resolution) from \(Paths.macOSTOMLName) (it was \(was))")
    }

    /// The Mac's own screen is off, so its size wasn't set.
    static var screenOff: Message {
        Message(
            .info, "the Mac's own screen is off, so [\(DisplaySettings.table)] in \(Paths.macOSTOMLName) was skipped")
    }
}

/// The words for why the screen's size couldn't be set.
extension DisplayError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .noScreen:
            "the Mac's own screen is off"
        case .unavailable(let resolution, let offered):
            "the screen can't show \(resolution), it can show \(offered.map(\.description).joined(separator: ", "))"
        case .refused(let code):
            "macOS turned it down (CoreGraphics error \(code))"
        }
    }
}
