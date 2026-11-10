import Foundation

/// Shows the picture `wallpaper` in `malum.toml` names, from the `wallpapers` folder in dots, on
/// every screen. Leaving the setting out leaves the wallpaper as it is.
@MainActor
struct Wallpaper {
    /// The setting in `[system_config]` that names the picture.
    nonisolated static let key = "wallpaper"

    /// The disk.
    private let files: any FileSystem
    /// Where the `wallpapers` folder is.
    private let paths: Paths
    /// Shows the picture.
    private let desktop: any Desktop

    /// Creates the part, which finds the picture on `files` and shows it through `desktop`.
    init(files: any FileSystem, paths: Paths, desktop: any Desktop) {
        self.files = files
        self.paths = paths
        self.desktop = desktop
    }

    /// Shows the picture `settings` names, from the dots folder `dots`, where a screen shows
    /// another one. Says whether it worked.
    func set(_ settings: ConfigTable, dots: String, report: (Message) -> Void) -> Bool {
        guard case .string(let name) = settings[Self.key] else { return true }
        let folder = paths.wallpapersFolder(in: dots)
        guard Paths.isPlainName(name), let file = picture(named: name, in: folder) else {
            report(.noWallpaper(name, in: folder))
            return false
        }
        let path = "\(folder)/\(file)"
        guard desktop.pictures().contains(where: { $0 != path }) else { return true }
        do {
            try desktop.show(path)
        } catch {
            report(.failed(.setWallpaper, error))
            return false
        }
        report(.wallpaperSet(file))
        return true
    }

    /// The file in `folder` called `name`, or else the one whose name without its extension is
    /// `name`, or nil when there's none.
    private func picture(named name: String, in folder: String) -> String? {
        let names = ((try? files.contents(of: folder)) ?? []).sorted()  // No folder: no pictures, reported.
        guard !names.contains(name) else { return name }
        return names.first { ($0 as NSString).deletingPathExtension == name }
    }
}
