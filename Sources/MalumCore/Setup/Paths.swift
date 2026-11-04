import Foundation

/// Where Malum keeps the few things that live outside dots.
public struct Paths: Equatable, Sendable {
    /// The user's home folder.
    public let home: String

    /// The folder for user config, relative to home.
    private static let configRoot = ".config"
    /// The name of the file that records where dots is.
    private static let configName = "config"
    /// The folder for the user's commands, relative to home. Getting it on `PATH` is dots' job.
    private static let binRoot = ".local/bin"
    /// The extension of Malum's config files in dots.
    private static let tomlExtension = "toml"
    /// The folder for apps' own data, relative to home.
    private static let applicationSupportRoot = "Library/Application Support"
    /// The folder Malum is installed in, relative to home.
    private static let applicationsRoot = "Applications"
    /// The folder of the user's login agents, relative to home.
    private static let launchAgentsRoot = "Library/LaunchAgents"
    /// The user's login keychain, relative to home.
    private static let loginKeychainPath = "Library/Keychains/login.keychain-db"
    /// The folder inside an app bundle that holds its executable.
    private static let executableFolder = "Contents/MacOS"

    /// Creates the paths under `home`.
    public init(home: String) {
        self.home = home
    }

    /// `~/.config/malum`.
    public var configDirectory: String { "\(home)/\(Self.configRoot)/\(Project.command)" }
    /// `~/.config/malum/config`, which records where dots is.
    public var configFile: String { "\(configDirectory)/\(Self.configName)" }
    /// `~/.local/bin`.
    public var binDirectory: String { "\(home)/\(Self.binRoot)" }
    /// `~/.local/bin/malum`, the link to Malum's executable.
    public var commandLink: String { "\(binDirectory)/\(Project.command)" }
    /// `~/Library/Application Support/<bundle ID>`, the state folder the app and the command share.
    public var stateDirectory: String { "\(home)/\(Self.applicationSupportRoot)/\(Project.bundleID)" }
    /// `~/Applications/Malum.app`, the installed app.
    public var installedBundle: String { "\(home)/\(Self.applicationsRoot)/\(Project.name).app" }
    /// `~/Applications/Malum.app/Contents/MacOS/Malum`, the executable of the installed app.
    public var installedExecutable: String { "\(installedBundle)/\(Self.executableFolder)/\(Project.name)" }
    /// `~/Library/Keychains/login.keychain-db`, where Malum's signing certificate goes.
    public var loginKeychain: String { "\(home)/\(Self.loginKeychainPath)" }
    /// `~/Library/LaunchAgents`, where the login agent goes.
    public var launchAgentsDirectory: String { "\(home)/\(Self.launchAgentsRoot)" }
    /// `~/Library/LaunchAgents/<bundle ID>.plist`, the agent that starts Malum at login.
    public var loginAgent: String { "\(launchAgentsDirectory)/\(Project.bundleID).plist" }

    /// `malum.toml`, the name of the file in dots that holds Malum's settings.
    public static var configTOMLName: String { "\(Project.command).\(tomlExtension)" }

    /// `packages.toml`, the name of the file in dots that lists what system config installs.
    public static let packagesTOMLName = "packages.toml"

    /// `malum.toml` at the top of the dots folder `dots`.
    public func configTOML(in dots: String) -> String { "\(dots)/\(Self.configTOMLName)" }

    /// `packages.toml` at the top of the dots folder `dots`.
    public func packagesTOML(in dots: String) -> String { "\(dots)/\(Self.packagesTOMLName)" }

    /// Turns `path` into an absolute, clean path, expanding `~` and reading it relative to `base`.
    public func resolve(_ path: String, relativeTo base: String) -> String {
        let expanded: String
        switch path {
        case "~":
            expanded = home
        case _ where path.hasPrefix("~/"):
            expanded = home + path.dropFirst()
        case _ where path.hasPrefix("/"):
            expanded = path
        default:
            expanded = base + "/" + path
        }
        return URL(fileURLWithPath: expanded).standardizedFileURL.path
    }
}
