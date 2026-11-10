/// The words for the wallpaper `malum.toml` picks.
extension MessageText {
    /// Showing the wallpaper.
    static let setWallpaper: MessageText = "set the wallpaper"
}

extension Message {
    /// The picture `file` from dots shows on every screen now.
    static func wallpaperSet(_ file: String) -> Message {
        Message(.info, "set the wallpaper to \(file) from \(Paths.wallpapersFolderName) in dots")
    }

    /// No picture called `name` is in `folder`.
    static func noWallpaper(_ name: String, in folder: String) -> Message {
        couldnt(.setWallpaper, "there's no picture called \(name) in \(private: folder)")
    }
}
