/// What the launcher works through.
@MainActor
public struct LauncherSystem {
    /// Reads the apps folders.
    let files: any FileSystem
    /// Where the apps folders are.
    let paths: Paths
    /// Keeps the launch counts.
    let state: StateFolder
    /// Opens an app when no module that opens apps runs.
    let apps: any AppControl
    /// Watches the apps folders.
    let folders: any FolderWatch
    /// The popup the launcher shows its list in.
    let popup: PopupCenter

    /// Gathers the parts the launcher needs.
    public init(
        files: any FileSystem, paths: Paths, state: StateFolder, apps: any AppControl, folders: any FolderWatch,
        popup: PopupCenter
    ) {
        self.files = files
        self.paths = paths
        self.state = state
        self.apps = apps
        self.folders = folders
        self.popup = popup
    }
}
