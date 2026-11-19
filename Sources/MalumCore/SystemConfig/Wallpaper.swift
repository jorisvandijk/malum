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
        guard let file = DotsPicture.file(named: name, in: folder, on: files) else {
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
}
