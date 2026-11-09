/// An app the launcher can start.
public struct LaunchableApp: Equatable, Sendable {
    /// The name Finder shows, without `.app`.
    public let name: String
    /// Where the app is.
    public let path: String
    /// Its bundle ID, nil when its `Info.plist` has none.
    public let bundleID: String?

    /// What its launch count is kept under: the bundle ID, or the path without one.
    public var key: String { bundleID ?? path }
}
