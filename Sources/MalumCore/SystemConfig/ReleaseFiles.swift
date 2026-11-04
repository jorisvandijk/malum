import Foundation

/// Works out which file of a release to install, and what to install from it once it's unpacked.
enum ReleaseFiles {
    /// Endings of the archives Malum unpacks with `tar`.
    static let tarballs = [".tar", ".tar.gz", ".tgz", ".tar.xz", ".txz", ".tar.bz2", ".tbz"]
    /// The ending of a zip file, which Malum unpacks with `ditto`.
    static let zip = ".zip"
    /// Endings of installers Malum can't install.
    private static let installers = [".dmg", ".pkg"]
    /// Endings of files that come along with a release but are never installed.
    private static let extras = [".sha256", ".sha512", ".md5", ".sig", ".asc", ".txt", ".md", ".json", ".sbom"]
    /// Words in a file's name that say it's for a Mac.
    private static let macWords = ["mac", "darwin", "apple"]
    /// Folders inside an archive that are never looked into.
    private static let skipped = ["__MACOSX"]
    /// How many folders deep an unpacked archive is searched.
    private static let depth = 3

    /// Whether the file `name` ends in one of `endings`.
    static func ends(_ name: String, with endings: [String]) -> Bool {
        endings.contains { name.lowercased().hasSuffix($0) }
    }

    /// The file of `release` that `entry` installs: the one its `asset` matches, or else the only
    /// file, or else the only file for a Mac.
    static func asset(for entry: ReleaseEntry, in release: Release) throws(ReleaseError) -> ReleaseAsset {
        let names = release.assets.map { "\"\($0.name)\"" }.joined(separator: ", ")
        let found = "\(entry.repo) \(release.tag) has \(names.isEmpty ? "no files" : names)"
        let chosen: ReleaseAsset
        if let pattern = entry.asset {
            let matches = release.assets.filter { fnmatch(pattern, $0.name, 0) == 0 }
            guard matches.count == 1, let match = matches.first else {
                throw ReleaseError("\(matches.count) files match \"\(pattern)\"; \(found)")
            }
            chosen = match
        } else {
            let files = release.assets.filter { !ends($0.name, with: extras) }
            let mac = files.filter { asset in macWords.contains { asset.name.lowercased().contains($0) } }
            switch (files.count, mac.count) {
            case (1, _):
                chosen = files[0]
            case (_, 1):
                chosen = mac[0]
            default:
                let table = "\(PackageList.releaseTable).\(ConfigValue.key(entry.name))"
                throw ReleaseError("can't tell which file to install, set asset in [\(table)]; \(found)")
            }
        }
        guard !ends(chosen.name, with: installers) else {
            throw ReleaseError("\"\(chosen.name)\" is an installer, which Malum can't install")
        }
        return chosen
    }

    /// The apps, programs and archives in `folder`, searched a few folders deep.
    static func contents(of folder: String, files: any FileSystem) throws -> Contents {
        var found = Contents()
        try collect(folder, depth: depth, into: &found, files: files)
        return found
    }

    /// Adds what's in `folder` to `found`, and looks into its folders while `depth` is left.
    private static func collect(_ folder: String, depth: Int, into found: inout Contents, files: any FileSystem) throws
    {
        for name in try files.contents(of: folder).sorted() where !name.hasPrefix(".") && !skipped.contains(name) {
            let path = "\(folder)/\(name)"
            switch files.item(at: path) {
            case .directory where name.hasSuffix(".app"):
                found.apps.append(path)
            case .directory where depth > 0:
                try collect(path, depth: depth - 1, into: &found, files: files)
            case .file where files.isExecutable(path):
                found.programs.append(path)
            case .file where ends(name, with: tarballs + [zip]):
                found.archives.append(path)
            default:
                continue
            }
        }
    }

    /// What to install from `found`: its one app, or else the program called `name`, or else its
    /// only program. Says whether it's an app.
    static func payload(in found: Contents, name: String) throws(ReleaseError) -> (path: String, isApp: Bool) {
        let file = { (path: String) in (path as NSString).lastPathComponent }
        if found.apps.count == 1, let app = found.apps.first { return (app, true) }
        if let app = found.apps.first(where: { file($0).lowercased() == "\(name.lowercased()).app" }) {
            return (app, true)
        }
        guard found.apps.isEmpty else { throw ReleaseError("it holds several apps, and none is called \(name).app") }
        if let program = found.programs.first(where: { file($0) == name }) { return (program, false) }
        if found.programs.count == 1, let program = found.programs.first { return (program, false) }
        throw ReleaseError(
            found.programs.isEmpty
                ? "it holds no app or program" : "it holds several programs, and none is called \(name)")
    }

    /// What an unpacked archive holds.
    struct Contents {
        /// The apps.
        var apps: [String] = []
        /// The programs.
        var programs: [String] = []
        /// Archives inside the archive.
        var archives: [String] = []
    }
}
