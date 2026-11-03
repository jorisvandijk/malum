/// How Malum was started: as the menu bar app, or as the command in a terminal.
public enum LaunchMode: Equatable, Sendable {
    /// Started by launchd, or opened from Finder or with `open`.
    case app
    /// Run from a terminal or a script.
    case command

    /// The variable in which launchd names the job that started a process.
    private static let serviceVariable = "XPC_SERVICE_NAME"
    /// How launchd names the job of an app opened from Finder or with `open`.
    private static let openedAppPrefix = "application."

    /// Reads the mode from the process's environment. launchd sets the service name to the job's
    /// label (Malum's bundle ID) for the agent, and to `application.<bundle ID>.<numbers>` for an
    /// app opened from Finder or with `open`. A terminal has a service name of its own, or none.
    public init(environment: [String: String]) {
        let service = environment[Self.serviceVariable] ?? ""
        let isApp = service == Project.bundleID || service.hasPrefix("\(Self.openedAppPrefix)\(Project.bundleID).")
        self = isApp ? .app : .command
    }
}
