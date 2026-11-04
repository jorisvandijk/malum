/// The system config module, which makes the Mac match dots. It has one switch, and does its work
/// only when `malum run` runs, never in the menu bar app.
public enum SystemConfig {
    /// The module's id, which is also the name of its table in `malum.toml`.
    public static let id = "system_config"

    /// The settings the module takes.
    public static let schema = ConfigSchema(
        about: """
            Makes the Mac match dots when you run `malum run`. Nothing happens in the background: \
            the app only reads these settings, and `malum run` does the work.
            """,
        settings: [
            PackageKind.formula.setting: Setting(
                .strings,
                """
                Homebrew formulae to install, by name, such as `"ripgrep"`. A formula from a tap is \
                written as `"owner/tap/name"`. `malum run` installs each one that isn't installed yet.
                """,
                default: .array([])),
            PackageKind.cask.setting: Setting(
                .strings,
                """
                Homebrew casks to install, by name, such as `"kitty"`. A cask from a tap is written as \
                `"owner/tap/name"`. `malum run` installs each one that isn't installed yet.
                """,
                default: .array([])),
        ])
}
