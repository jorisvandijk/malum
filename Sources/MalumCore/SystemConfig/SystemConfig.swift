/// The system config module, which makes the Mac match dots. It has one switch, and does its work
/// only when `malum run` runs, never in the menu bar app.
public enum SystemConfig {
    /// The module's id, which is also the name of its table in `malum.toml`.
    public static let id = "system_config"

    /// The settings the module takes. What it installs is listed in `packages.toml`, not here.
    public static let schema = ConfigSchema(
        about: """
            Makes the Mac match dots when you run `malum run`, installing what `packages.toml` lists. \
            Nothing happens in the background: the app only reads the switch, and `malum run` does the work.
            """,
        settings: [
            ReleaseFolders.appsKey: Setting(
                .string, "The folder apps from GitHub releases are installed in.",
                default: .string(ReleaseFolders.defaultApps)),
            ReleaseFolders.programsKey: Setting(
                .string, "The folder programs from GitHub releases are installed in.",
                default: .string(ReleaseFolders.defaultPrograms)),
        ])
}
