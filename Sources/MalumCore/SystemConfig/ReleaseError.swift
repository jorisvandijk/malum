/// Why one GitHub release couldn't be installed.
enum ReleaseError: Error, Equatable {
    /// The repository has no published release, or it's private.
    case noRelease(repo: String)
    /// The `asset` pattern matched a number of files other than one; `found` lists what's there.
    case assetMatches(count: Int, pattern: String, found: String)
    /// No single file fits without `asset`, which goes in the table; `found` lists what's there.
    case unclearAsset(table: String, found: String)
    /// The chosen file is an installer.
    case installer(name: String)
    /// Unpacking the archive at the path failed.
    case unpackable(path: String, reason: String)
    /// The download holds archives inside archives, deeper than Malum unpacks.
    case nestedArchives
    /// The download holds several apps, and none has the release's name.
    case severalApps(name: String)
    /// The download holds several programs, and none has the release's name.
    case severalPrograms(name: String)
    /// The download holds no app or program.
    case nothingToInstall
    /// Something Malum didn't install is already at the path.
    case taken(path: String)
}
