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
