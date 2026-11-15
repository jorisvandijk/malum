/// Every way Malum runs `sips`, macOS's picture converter.
public enum Sips {
    /// Where macOS keeps `sips`.
    public static let path = "/usr/bin/sips"
    /// The size, in pixels, an app icon is made at, one of the sizes an icon file holds.
    private static let iconPixels = "512"

    /// Turns the square picture `picture`, such as a PNG of any size, into the app icon file `icon`.
    public static func icon(from picture: String, to icon: String) -> Command {
        Command(path, ["-z", iconPixels, iconPixels, "-s", "format", "icns", picture, "--out", icon])
    }
}
