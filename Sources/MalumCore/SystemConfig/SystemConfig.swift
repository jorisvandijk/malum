/// The system config module, which makes the Mac match dots. It has one switch, and does its work
/// only when `malum run` runs, never in the menu bar app.
public enum SystemConfig {
    /// The module's id, which is also the name of its table in `malum.toml`.
    public static let id = "system_config"

    /// The settings the module takes. What it installs and writes is listed in `packages.toml`, `apps/` and `macos.toml`, not here.
    public static let schema = ConfigSchema(
        about: """
            Makes the Mac match dots when you run `malum run`, installing what `packages.toml` lists, \
            writing the app config files and preferences in `apps/` and setting the macOS settings in `macos.toml`. \
            At the end of the run, \(Project.name) updates itself. \
            Nothing happens in the background: the app only reads the switch, and `malum run` does the work.
            """,
        settings: [
            ReleaseFolders.appsKey: Setting(
                .string, "The folder apps from GitHub releases are installed in.",
                default: .string(ReleaseFolders.defaultApps)),
            ReleaseFolders.programsKey: Setting(
                .string, "The folder programs from GitHub releases are installed in.",
                default: .string(ReleaseFolders.defaultPrograms)),
            TerminalLaunch.key: Setting(
                .string,
                """
                The terminal app, by its bundle ID, that Run and Show log in the menu open in, such as \
                `net.kovidgoyal.kitty`. A running kitty that listens on `unix:/tmp/kitty` gets a new tab; \
                otherwise a new window opens with `-e` and the command to run. Left out, they show their \
                output in the popup.
                """),
            Wallpaper.key: Setting(
                .string,
                """
                The picture every screen shows, by its file name in the `\(Paths.wallpapersFolderName)` folder \
                in dots, with or without its extension. Left out, the wallpaper stays as it is.
                """),
            UserPicture.key: Setting(
                .string,
                """
                Your user picture, on the login screen and in Users & Groups, by its file name in the \
                `\(Paths.picturesFolderName)` folder in dots, with or without its extension. Its middle square is \
                used. Left out, the user picture stays as it is.
                """),
        ])
}
