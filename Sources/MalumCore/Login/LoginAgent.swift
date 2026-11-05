import Foundation

/// The LaunchAgent that starts Malum at login and restarts it after a crash.
///
/// The file is the same for every version of Malum, since it points at the installed app's fixed
/// path. macOS announces "Background Items Added" when a login agent appears or changes, so keeping
/// it byte for byte the same means the announcement comes once, not with every update.
public struct LoginAgent: Sendable {
    /// Seconds launchd waits before starting Malum again after a crash, so a crash at startup
    /// doesn't spin.
    private static let restartDelay = 10

    /// The disk.
    private let files: any FileSystem
    /// Where the agent and the installed app are.
    private let paths: Paths

    /// Creates the agent's writer.
    public init(files: any FileSystem, paths: Paths) {
        self.files = files
        self.paths = paths
    }

    /// Writes the login agent when it's missing or differs, as the app does at every start.
    /// `executable` is the running executable with its links resolved, or nil when Malum doesn't run
    /// from an app bundle. Only the installed app writes the agent, so a build elsewhere never
    /// points login at an app that isn't there.
    public func update(executable: String?) throws(FileSystemError) -> LoginAgentChange {
        guard paths.isInstalled(executable: executable, files: files) else { return .notInstalled }
        let wanted = Self.plist(program: paths.installedExecutable)
        guard current() != wanted else { return .unchanged }
        try files.createDirectory(paths.launchAgentsDirectory)
        try files.write(wanted, to: paths.loginAgent)
        return .written
    }

    /// The text of the agent that's there now, or nil when there's none.
    private func current() -> String? {
        guard files.item(at: paths.loginAgent) == .file else { return nil }
        return try? files.read(paths.loginAgent)  // One that can't be read is written again, like a missing one.
    }

    /// The agent's file, starting `program` at login. `KeepAlive` with `SuccessfulExit` false
    /// restarts Malum when it crashes, but not when it quits, so Quit isn't undone.
    static func plist(program: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(Escaping.xml(Project.bundleID))</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(Escaping.xml(program))</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <dict>
                <key>SuccessfulExit</key>
                <false/>
            </dict>
            <key>ThrottleInterval</key>
            <integer>\(restartDelay)</integer>
            <key>ProcessType</key>
            <string>Interactive</string>
            <key>LimitLoadToSessionType</key>
            <string>Aqua</string>
        </dict>
        </plist>

        """
    }
}
