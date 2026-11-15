/// `[home_folders] show` in `macos.toml`: the folders in the home folder Finder shows. Every other
/// folder there that Finder shows is hidden with `chflags hidden`, and a listed one that's hidden is
/// shown again. Names match without regard to case, as the disk does. Taking the table out leaves
/// the folders as they are.
@MainActor
struct HomeFolders {
    /// The table of home folders.
    static let table = "home_folders"
    /// The key in `[home_folders]` that lists the folders to show.
    private static let showKey = "show"

    /// Hides and shows the folders.
    private let runner: any CommandRunner
    /// The disk, where the home folder is.
    private let files: any FileSystem
    /// Where the home folder is.
    private let paths: Paths

    /// Creates the part, which looks at the home folder in `paths` on `files` and changes it with `runner`.
    init(runner: any CommandRunner, files: any FileSystem, paths: Paths) {
        self.runner = runner
        self.files = files
        self.paths = paths
    }

    /// The names in `[home_folders] show`, or nil when there's no such table, adding a problem to
    /// `reader` when it's wrong.
    static func read(_ reader: inout TableReader) -> [String]? {
        guard reader.document[table] != nil else { return nil }
        return reader.onlyList(showKey, of: table, check: Paths.isPlainName, problem: MessageText.notPlainName)
    }

    /// Shows the folders in `shown` and hides every other one, leaving them all when it's nil.
    /// Says whether everything worked.
    func set(_ shown: [String]?, report: (Message) -> Void) async -> Bool {
        guard let shown else { return true }
        let names: [String]
        do {
            names = try files.contents(of: paths.home)
        } catch {
            report(.failed(.setHomeFolders, error))
            return false
        }
        var succeeded = true
        for name in names.sorted() where !name.hasPrefix(".") {
            let path = "\(paths.home)/\(name)"
            let show = shown.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
            guard files.item(at: path) == .directory, files.isHidden(path) == show else { continue }
            let result = await runner.run(show ? Chflags.show(path) : Chflags.hide(path))
            guard result.succeeded else {
                report(.homeFolderUnchanged(name, shown: show, reason: result.reason))
                succeeded = false
                continue
            }
            report(.homeFolderChanged(name, shown: show))
        }
        return succeeded
    }
}
