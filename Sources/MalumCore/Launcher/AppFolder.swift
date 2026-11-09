/// A folder the launcher looks for apps in.
public struct AppFolder: Equatable, Sendable {
    /// Apple's own apps.
    private static let systemApplications = "/System/Applications"
    /// The folder Finder is in.
    private static let coreServices = "/System/Library/CoreServices"
    /// Finder, the one app taken from `coreServices`.
    private static let finder = "Finder.app"
    /// How deep the apps folders are searched, for folders such as `Utilities` and Nix's
    /// `Nix Apps`.
    private static let appsDepth = 2

    /// Where it is.
    public let path: String
    /// How many folder levels below `path` are searched too: 0 is `path` itself only.
    public let depth: Int
    /// When set, only apps with these file names are taken from it.
    public let only: Set<String>?

    /// Creates a folder to search.
    public init(path: String, depth: Int, only: Set<String>? = nil) {
        self.path = path
        self.depth = depth
        self.only = only
    }

    /// `/Applications`, `~/Applications` (with Safari's web apps), Apple's apps and Finder. An app
    /// in more than one keeps the first.
    public static func standard(paths: Paths) -> [AppFolder] {
        [
            AppFolder(path: Paths.systemApplications, depth: appsDepth),
            AppFolder(path: paths.userApplications, depth: appsDepth),
            AppFolder(path: systemApplications, depth: 1),
            AppFolder(path: coreServices, depth: 0, only: [finder]),
        ]
    }
}
