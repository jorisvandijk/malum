/// Every way Malum runs `launchctl`.
public enum Launchctl {
    /// The tool.
    private static let path = "/usr/bin/launchctl"

    /// The login session of the user with id `userID`, where login agents run.
    public static func domain(userID: UInt32) -> String { "gui/\(userID)" }

    /// The job with `label` in the login session of the user with id `userID`.
    public static func service(_ label: String, userID: UInt32) -> String { "\(domain(userID: userID))/\(label)" }

    /// Describes the job `service`. It succeeds only when the job is loaded.
    public static func describe(_ service: String) -> Command {
        Command(path, ["print", service])
    }

    /// Loads the agent in the file `plist` into `domain`, which starts it when it runs at load.
    public static func load(_ plist: String, into domain: String) -> Command {
        Command(path, ["bootstrap", domain, plist])
    }

    /// Stops the job `service` when it runs, and starts it again.
    public static func restart(_ service: String) -> Command {
        Command(path, ["kickstart", "-k", service])
    }
}
