/// The config reference in `docs/`, made from the modules' schemas so it always matches what
/// `malum.toml` takes.
public enum ConfigDocs {
    /// Where the page goes, from the top of the repository.
    public static let path = "docs/config.md"

    /// The start of the page, before the modules.
    private static let header = """
        <!-- Made from the modules' schemas by `swift run MalumDocs`. Edit the schemas, not this page. -->

        # Config reference

        Every setting `malum.toml` takes, by module. Each module's settings go in a table named after \
        the module, such as `[window_manager]`. A setting that's left out takes its default, when it \
        has one.

        """

    /// The page for the modules with these schemas, by the module's id.
    public static func page(for schemas: [String: ConfigSchema]) -> String {
        guard !schemas.isEmpty else {
            return header + "\nNo module takes settings, so `malum.toml` has nothing to set.\n"
        }
        return header + schemas.sorted { $0.key < $1.key }.map(section).joined()
    }

    /// The part of the page about one module and its settings.
    private static func section(_ module: (key: String, value: ConfigSchema)) -> String {
        let name = ConfigValue.key(module.key)
        let settings = module.value.settings.sorted { $0.key < $1.key }.map { key, setting in
            entry("\(name).\(ConfigValue.key(key))", setting)
        }
        return "\n## `\(name)`\n\n\(module.value.about)\n" + settings.joined()
    }

    /// The part of the page about one setting, under its full name.
    private static func entry(_ name: String, _ setting: Setting) -> String {
        let value = "- Value: \(setting.kind)\n"
        let fallback = setting.defaultValue.map { "- Default: `\($0.toml)`\n" } ?? ""
        return "\n### `\(name)`\n\n\(setting.about)\n\n" + value + fallback
    }
}
