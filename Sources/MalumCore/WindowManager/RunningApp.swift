/// A running app, as run or raise and hiding the others see it.
public struct RunningApp: Equatable, Sendable {
    /// Its process ID.
    public let pid: Int32
    /// Its bundle ID, or nil when it has none.
    public let bundleID: String?
    /// Its name, for the log.
    public let name: String
    /// Whether it's the frontmost app.
    public let isActive: Bool
    /// Whether it's hidden.
    public let isHidden: Bool
    /// Whether it's an ordinary app with a Dock icon, not one that only runs in the menu bar or background.
    public let isRegular: Bool

    /// Creates the app's description.
    public init(pid: Int32, bundleID: String?, name: String, isActive: Bool, isHidden: Bool, isRegular: Bool) {
        self.pid = pid
        self.bundleID = bundleID
        self.name = name
        self.isActive = isActive
        self.isHidden = isHidden
        self.isRegular = isRegular
    }
}
