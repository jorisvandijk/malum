/// Every app system config writes config files for, each described by its files and their
/// formats.
enum AppConfigs {
    /// The apps, each read from `apps/<name>.toml`.
    static let all = [
        AppConfig(
            name: "git",
            files: [
                AppConfigFile(".config/git/config", .ini(table: "settings"), always: true),
                AppConfigFile(".config/git/ignore", .list(table: "ignore", key: "patterns")),
                AppConfigFile(".config/git/attributes", .list(table: "attributes", key: "lines")),
            ]),
        AppConfig(
            name: "kitty",
            files: [
                // The theme comes first, so a setting wins over it.
                AppConfigFile(
                    ".config/kitty/kitty.conf",
                    .lines([LineBlock("theme"), LineBlock("settings"), LineBlock("keybindings", prefix: "map")]),
                    always: true)
            ]),
        AppConfig(
            name: "micro",
            files: [
                AppConfigFile(".config/micro/settings.json", .json(table: "settings"), always: true),
                AppConfigFile(".config/micro/bindings.json", .json(table: "bindings")),
                AppConfigFile(
                    ".config/micro/colorschemes/*.micro", .lines([LineBlock(nil, prefix: "color-link", quoted: true)]),
                    each: "colorschemes"),
            ]),
        AppConfig(
            name: "newsboat",
            files: [
                AppConfigFile(
                    ".config/newsboat/config",
                    .lines([
                        LineBlock("settings", quoted: true), LineBlock("keybindings", prefix: "bind-key"),
                        LineBlock("ignore_articles", prefix: "ignore-article", quoted: true),
                    ]),
                    always: true),
                AppConfigFile(".config/newsboat/urls", .feeds(table: "feeds")),
            ]),
    ]

    /// The app called `name`, or nil when there's none.
    static func app(named name: String) -> AppConfig? {
        all.first { $0.name == name }
    }
}
