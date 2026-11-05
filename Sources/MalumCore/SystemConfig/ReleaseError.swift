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

// MARK: - ReportableError

extension ReleaseError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .noRelease(let repo):
            "\(repo) has no published release on GitHub, or it's private"
        case .assetMatches(let count, let pattern, let found):
            "\(count) files match \"\(pattern)\"; \(found)"
        case .unclearAsset(let table, let found):
            "can't tell which file to install, set asset in [\(table)]; \(found)"
        case .installer(let name):
            "\"\(name)\" is an installer, which \(Project.name) can't install"
        case .unpackable(let path, let reason):
            "couldn't unpack \(private: path): \(reason)"
        case .nestedArchives:
            "it holds archives inside archives"
        case .severalApps(let name):
            "it holds several apps, and none is called \(name).app"
        case .severalPrograms(let name):
            "it holds several programs, and none is called \(name)"
        case .nothingToInstall:
            "it holds no app or program"
        case .taken(let path):
            "\(private: path) is already there, and \(Project.name) didn't install it"
        }
    }
}
