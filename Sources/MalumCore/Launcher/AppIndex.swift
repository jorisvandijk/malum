import Foundation

/// Finds every app in the launcher's folders.
public struct AppIndex: Sendable {
    /// The end of an app bundle's name.
    private static let appExtension = ".app"

    /// The disk.
    private let files: any FileSystem

    /// Creates an index that reads `files`.
    public init(files: any FileSystem) {
        self.files = files
    }

    /// Every app in `folders`, once per bundle ID (the first folder wins), sorted by name. Links
    /// are followed, since Nix puts links to its apps in `Nix Apps`.
    public func apps(in folders: [AppFolder]) -> [LaunchableApp] {
        var found: [LaunchableApp] = []
        var seen = Set<String>()
        for folder in folders {
            collect(in: folder.path, depth: folder.depth, only: folder.only, into: &found, seen: &seen)
        }
        return found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Adds the apps in `folder` and, while `depth` allows, in the folders inside it.
    private func collect(
        in folder: String, depth: Int, only: Set<String>?, into found: inout [LaunchableApp], seen: inout Set<String>
    ) {
        let names = (try? files.contents(of: folder)) ?? []  // Missing or unreadable: no apps there.
        for name in names.sorted() where !name.hasPrefix(".") {
            let path = "\(folder)/\(name)"
            guard isFolder(path) else { continue }
            guard name.hasSuffix(Self.appExtension) else {
                if depth > 0, only == nil { collect(in: path, depth: depth - 1, only: nil, into: &found, seen: &seen) }
                continue
            }
            guard only?.contains(name) ?? true, let app = app(at: path, named: name) else { continue }
            if seen.insert(app.key).inserted { found.append(app) }
        }
    }

    /// The app at `path`, whose file name is `name`.
    private func app(at path: String, named name: String) -> LaunchableApp? {
        let shown = String(name.dropLast(Self.appExtension.count))
        guard !shown.isEmpty else { return nil }
        return LaunchableApp(name: shown, path: path, bundleID: AppBundle.bundleID(of: path, files: files))
    }

    /// Whether `path` is a folder, or a link to one.
    private func isFolder(_ path: String) -> Bool {
        files.item(at: files.canonicalPath(path)) == .directory
    }
}
