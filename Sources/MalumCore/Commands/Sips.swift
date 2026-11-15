/// Every way Malum runs `sips`, macOS's picture converter.
public enum Sips {
    /// Where macOS keeps `sips`.
    public static let path = "/usr/bin/sips"

    /// Turns the picture `picture`, such as a PNG, into the app icon file `icon`.
    public static func icon(from picture: String, to icon: String) -> Command {
        Command(path, ["-s", "format", "icns", picture, "--out", icon])
    }
}
