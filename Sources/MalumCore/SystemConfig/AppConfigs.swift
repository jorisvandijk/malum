/// Every app system config writes config files for.
enum AppConfigs {
    /// The apps, each read from `apps/<name>.toml`.
    static let all: [any AppConfig] = [GitConfig(), KittyConfig(), MicroConfig()]

    /// The app called `name`, or nil when there's none.
    static func app(named name: String) -> (any AppConfig)? {
        all.first { $0.name == name }
    }
}
