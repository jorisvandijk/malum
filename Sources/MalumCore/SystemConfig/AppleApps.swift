import Foundation

/// Removes the Apple apps `[apple_apps] remove` in `macos.toml` lists from `/Applications`, as
/// root through the run's one password prompt. It removes them on every run, so one that the App
/// Store or a macOS update puts back goes again. Only apps whose bundle ID is Apple's are removed.
@MainActor
struct AppleApps {
    /// The table of Apple apps.
    static let table = "apple_apps"
    /// The key in `[apple_apps]` that lists the apps to remove.
    static let removeKey = "remove"
    /// Where the Apple apps are.
    private static let folder = "/Applications"
    /// What every Apple app's bundle ID starts with.
    private static let applePrefix = "com.apple."

    /// Removes the apps.
    private let runner: any CommandRunner
    /// The disk, where the apps are.
    private let files: any FileSystem
    /// Gets root.
    private let sudo: SudoSession

    /// Creates the remover, which finds the apps on `files` and removes them with `runner` as root
    /// through `sudo`.
    init(runner: any CommandRunner, files: any FileSystem, sudo: SudoSession) {
        self.runner = runner
        self.files = files
        self.sudo = sudo
    }

    /// The names of the apps in `[apple_apps] remove`, adding a problem to `reader` when it's wrong.
    static func read(_ reader: inout TableReader) -> [String] {
        let apps = reader.table(reader.document, table, at: [])
        reader.unknownKeys(apps, at: [table], known: [removeKey])
        guard let value = apps[removeKey] else { return [] }
        let path = [table, removeKey]
        guard let names = TableReader.texts(value) else {
            reader.expect(path, SettingKind.strings)
            return []
        }
        guard names.allSatisfy(Paths.isPlainName) else {
            reader.add(.error, at: path, .notPlainName(TableReader.dotted(path)))
            return []
        }
        return names
    }

    /// Removes each app in `names` that's in `/Applications`. Says whether everything worked.
    func remove(_ names: [String], report: (Message) -> Void) async -> Bool {
        var succeeded = true
        for name in names {
            let path = "\(Self.folder)/\(name).app"
            guard files.item(at: path) == .directory else { continue }
            let bundleID = AppBundle.bundleID(of: path, files: files)
            guard let bundleID, bundleID.hasPrefix(Self.applePrefix) else {
                report(.notAppleApp(path, bundleID: bundleID))
                succeeded = false
                continue
            }
            guard await sudo.authorize(for: .removeAppleApps, report: report) else { return false }
            let removed = await runner.run(Sudo.asRoot(Remove.folder(path)))
            report(removed.succeeded ? .removedAppleApp(path) : .appleAppNotRemoved(path, reason: removed.reason))
            succeeded = removed.succeeded && succeeded
        }
        return succeeded
    }
}
