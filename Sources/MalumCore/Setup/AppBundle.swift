import Foundation

/// Finds out whether Malum runs from inside its app bundle, and reads an app bundle's `Info.plist`.
public enum AppBundle {
    /// The folder in a bundle that holds the executable.
    private static let executableFolder = "MacOS"
    /// The folder in a bundle that holds everything else.
    private static let contentsFolder = "Contents"
    /// The extension of an app bundle.
    private static let bundleExtension = "app"
    /// The key in `Info.plist` that holds the bundle ID.
    private static let bundleIDKey = "CFBundleIdentifier"
    /// The key in `Info.plist` that holds the version.
    private static let versionKey = "CFBundleShortVersionString"

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

    /// Whether `text` can be a bundle ID: not empty and without spaces.
    static func isBundleID(_ text: String) -> Bool {
        !text.isEmpty && !text.contains(where: \.isWhitespace)
    }

    /// The bundle ID of the app bundle `bundle` on `files`, such as `com.apple.garageband10`, or nil
    /// when its `Info.plist` can't be read or has none.
    public static func bundleID(of bundle: String, files: any FileSystem) -> String? {
        info(bundleIDKey, of: bundle, files: files)
    }

    /// The version of the app bundle `bundle` on `files`, such as `0.2.0`, or nil when its
    /// `Info.plist` can't be read or has none.
    public static func version(of bundle: String, files: any FileSystem) -> String? {
        info(versionKey, of: bundle, files: files)
    }

    /// The text under `key` in the `Info.plist` of `bundle`, or nil when there's none. Foundation reads
    /// both the XML and the binary form.
    private static func info(_ key: String, of bundle: String, files: any FileSystem) -> String? {
        guard let data = try? files.data(at: Paths.info(of: bundle)),  // No Info.plist, no answer.
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),  // Nor a bad one.
            let info = plist as? [String: Any], let text = info[key] as? String, !text.isEmpty
        else { return nil }
        return text
    }
}
