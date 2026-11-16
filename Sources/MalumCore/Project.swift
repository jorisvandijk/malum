/// The values that name Malum, defined once so nothing else spells them out.
///
/// `scripts/bundle.sh` reads them to stamp `Info.plist`, so each stays a single
/// `public static let name = "value"` line.
public enum Project {
    /// The app's name, as the user sees it.
    public static let name = "Malum"
    /// The name of the command in the terminal.
    public static let command = "malum"
    /// The bundle identifier, also used as the log subsystem and the state folder's name.
    public static let bundleID = "com.jorisvandijk.malum"
    /// The repository's `owner/name`, as GitHub's API names it.
    public static let repository = "jorisvandijk/malum"
    /// Where the source and the releases live.
    public static let repositoryURL = "https://github.com/\(repository)"
    /// Who makes Malum, as the About window names them.
    public static let author = "Joris van Dijk"
    /// Malum's website, which the About window links to.
    public static let website = "https://malum.jorisvandijk.com"
    /// The secrets folder's name for the GitHub token that lets Malum see its repository while it's private.
    public static let tokenService = "github"
    /// The secrets folder's name for the Samba passwords, whose account is `user@host`.
    public static let sambaService = "samba"
    /// What the release's zip file adds to the app's name.
    public static let assetSuffix = "-macos-arm64.zip"
    /// The version. The release workflow writes the tag's version here before it builds.
    public static let version = "dev"
}
