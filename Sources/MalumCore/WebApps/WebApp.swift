/// One site from `webapps.toml` that becomes a small app of its own in `~/Applications`.
public struct WebApp: Equatable, Sendable {
    /// What every web app's bundle ID starts with, so Malum can tell its web apps from other apps.
    public static let bundleIDPrefix = "\(Project.bundleID).webapp."
    /// The name of the icon file inside the bundle's `Contents/Resources`.
    static let iconName = "AppIcon"
    /// The icon file's extension.
    static let iconExtension = "icns"

    /// The app's name, which names its bundle and shows in cmd+tab and the launcher.
    public let name: String
    /// The site it opens, `http` or `https`.
    public let url: String
    /// Its icon, a PNG or ICNS file's path inside dots, or nil for the plain app icon.
    public let icon: String?

    /// Its bundle ID: the prefix and the name in lowercase letters and digits.
    public var bundleID: String {
        Self.bundleIDPrefix + name.lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

    /// Its bundle, `<name>.app` in `~/Applications`.
    public func bundle(_ paths: Paths) -> String {
        "\(paths.userApplications)/\(name).app"
    }

    /// Its `Info.plist`: the name, bundle ID and site, the icon when it has one, and permission to
    /// load plain `http` and local network sites, which a self-hosted service such as Frigate often is.
    /// `source` is a fingerprint of the web app executable and the icon it was built from, so a
    /// bundle whose `Info.plist` matches needs nothing done.
    func infoPlist(source: String) -> String {
        var info: ConfigTable = [
            "CFBundlePackageType": .string("APPL"),
            "CFBundleInfoDictionaryVersion": .string("6.0"),
            "CFBundleName": .string(name),
            "CFBundleDisplayName": .string(name),
            "CFBundleIdentifier": .string(bundleID),
            "CFBundleExecutable": .string(WebAppInfo.executable),
            "NSHighResolutionCapable": .boolean(true),
            "NSLocalNetworkUsageDescription": .string(WebAppWords.localNetwork(name)),
            "NSAppTransportSecurity": .table([
                "NSAllowsArbitraryLoadsInWebContent": .boolean(true), "NSAllowsLocalNetworking": .boolean(true),
            ]),
            WebAppInfo.urlKey: .string(url),
            WebAppInfo.sourceKey: .string(source),
        ]
        if icon != nil {
            info["CFBundleIconFile"] = .string(Self.iconName)
        }
        return PlistText.document(.table(info)) ?? ""  // Text and true only, which always make a document.
    }
}
