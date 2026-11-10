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
    static let binRoot = ".local/bin"
    /// The extension of Malum's config files in dots.
    static let tomlExtension = "toml"
    /// The folder for apps' own data, relative to home.
    static let applicationSupportRoot = "Library/Application Support"
    /// The folder of the apps every user has, where casks and the App Store put them.
    static let systemApplications = "/Applications"
    /// The folder Malum is installed in, relative to home.
    private static let applicationsRoot = "Applications"
    /// The folder of the user's login agents, relative to home.
    private static let launchAgentsRoot = "Library/LaunchAgents"
    /// The user's login keychain, relative to home.
    private static let loginKeychainPath = "Library/Keychains/login.keychain-db"
    /// The folder inside an app bundle that holds its executable.
    private static let executableFolder = "Contents/MacOS"
    /// An app bundle's `Info.plist`.
    private static let infoFile = "Contents/Info.plist"
    /// The state folder's folder that keeps the version an update replaced.
    private static let previousFolder = "previous"

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
    public var installedBundle: String { "\(userApplications)/\(Project.name).app" }

    /// The user's own apps folder, `~/Applications`, where Malum and Safari's web apps are.
    public var userApplications: String { "\(home)/\(Self.applicationsRoot)" }
    /// `~/Applications/Malum.app/Contents/MacOS/Malum`, the executable of the installed app.
    public var installedExecutable: String { Self.executable(in: installedBundle) }
    /// The state folder's `previous/Malum.app`, the version the last update replaced, for `malum rollback`.
    public var previousBundle: String { "\(stateDirectory)/\(Self.previousFolder)/\(Project.name).app" }

    /// Malum's executable inside the app bundle `bundle`.
    public static func executable(in bundle: String) -> String {
        "\(bundle)/\(executableFolder)/\(Project.name)"
    }

    /// The `Info.plist` of the app bundle `bundle`.
    public static func info(of bundle: String) -> String { "\(bundle)/\(infoFile)" }
    /// `~/Library/Keychains/login.keychain-db`, where Malum's signing certificate goes.
    public var loginKeychain: String { "\(home)/\(Self.loginKeychainPath)" }
    /// `~/Library/LaunchAgents`, where the login agent goes.
    public var launchAgentsDirectory: String { "\(home)/\(Self.launchAgentsRoot)" }
    /// `~/Library/LaunchAgents/<bundle ID>.plist`, the agent that starts Malum at login.
    public var loginAgent: String { "\(launchAgentsDirectory)/\(Project.bundleID).plist" }

    /// `malum.toml`, the name of the file in dots that holds Malum's settings.
    public static var configTOMLName: String { "\(Project.command).\(tomlExtension)" }

    /// `packages.toml`, the name of the file in dots that lists what system config installs.
    public static var packagesTOMLName: String { "packages.\(tomlExtension)" }

    /// `macos.toml`, the name of the file in dots that holds macOS's settings.
    public static var macOSTOMLName: String { "macos.\(tomlExtension)" }

    /// `<module>.toml`, the name of the file in dots that can hold `module`'s settings instead of
    /// its table in `malum.toml`.
    public static func moduleTOMLName(_ module: String) -> String { "\(module).\(tomlExtension)" }

    /// `apps`, the folder in dots that holds one file for each app whose config Malum writes.
    public static let appsFolderName = "apps"

    /// `apps/<name>.toml`, the file in dots for the app called `name`.
    public static func appFile(named name: String) -> String { "\(appsFolderName)/\(name).\(tomlExtension)" }

    /// The `apps` folder at the top of the dots folder `dots`.
    public func appsFolder(in dots: String) -> String { "\(dots)/\(Self.appsFolderName)" }

    /// The name of the folder in dots that holds the wallpapers.
    public static let wallpapersFolderName = "wallpapers"

    /// The folder of wallpapers in the dots folder `dots`.
    public func wallpapersFolder(in dots: String) -> String { "\(dots)/\(Self.wallpapersFolderName)" }

    /// `malum.toml` at the top of the dots folder `dots`.
    public func configTOML(in dots: String) -> String { "\(dots)/\(Self.configTOMLName)" }

    /// `<module>.toml` at the top of the dots folder `dots`.
    public func moduleTOML(_ module: String, in dots: String) -> String { "\(dots)/\(Self.moduleTOMLName(module))" }

    /// `packages.toml` at the top of the dots folder `dots`.
    public func packagesTOML(in dots: String) -> String { "\(dots)/\(Self.packagesTOMLName)" }

    /// `macos.toml` at the top of the dots folder `dots`.
    public func macOSTOML(in dots: String) -> String { "\(dots)/\(Self.macOSTOMLName)" }

    /// Whether `name` is safe as a single file name: it isn't empty, doesn't start with a dot and
    /// holds no `/`, so it can't reach outside the folder it's put in.
    public static func isPlainName(_ name: String) -> Bool {
        !name.isEmpty && !name.hasPrefix(".") && !name.contains("/")
    }

    /// The folder `path` is in.
    public static func folder(of path: String) -> String {
        (path as NSString).deletingLastPathComponent
    }

    /// Whether `executable`, the running executable with its links resolved, is the installed
    /// app's, or false when it's nil because Malum doesn't run from an app bundle.
    public func isInstalled(executable: String?, files: any FileSystem) -> Bool {
        guard let executable else { return false }
        return files.canonicalPath(executable) == files.canonicalPath(installedExecutable)
    }

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
