/// The settings every part of Malum takes in `malum.toml`, by the name of its table.
public enum ConfigSchemas {
    /// Every module's schema, plus system config's, which `malum run` uses and the app only reads.
    @MainActor
    public static var all: [String: ConfigSchema] {
        Modules.schemas.merging([SystemConfig.id: SystemConfig.schema]) { module, _ in module }
    }
}
