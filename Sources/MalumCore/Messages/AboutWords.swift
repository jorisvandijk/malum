/// The About window's own words.
public enum AboutWords {
    /// The window's title.
    public static let title = "About \(Project.name)"

    /// The line that gives Malum's version.
    public static func version(_ version: String) -> String {
        "Version \(version)"
    }
}
