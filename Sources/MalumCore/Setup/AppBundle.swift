import Foundation

/// Finds out whether Malum runs from inside its app bundle.
public enum AppBundle {
    /// The folder in a bundle that holds the executable.
    private static let executableFolder = "MacOS"
    /// The folder in a bundle that holds everything else.
    private static let contentsFolder = "Contents"
    /// The extension of an app bundle.
    private static let bundleExtension = "app"

    /// `path` when it is the executable inside an app bundle, or nil when Malum runs from elsewhere,
    /// such as a build folder. `path` has its links already resolved.
    public static func executable(at path: String) -> String? {
        let macOS = URL(fileURLWithPath: path).deletingLastPathComponent()
        let contents = macOS.deletingLastPathComponent()
        let bundle = contents.deletingLastPathComponent()
        guard macOS.lastPathComponent == executableFolder,
            contents.lastPathComponent == contentsFolder,
            bundle.pathExtension == bundleExtension
        else { return nil }
        return path
    }
}
