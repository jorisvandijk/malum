/// The settings every part of Malum takes in `malum.toml`, by the name of its table.
public enum ConfigSchemas {
    /// The schemas of `modules`, plus system config's, which `malum run` uses and the app only reads.
    @MainActor
    public static func all(modules: [any Module]) -> [String: ConfigSchema] {
        Dictionary(modules.map { ($0.id, $0.schema) }) { first, _ in first }
            .merging([SystemConfig.id: SystemConfig.schema]) { module, _ in module }
    }
}
