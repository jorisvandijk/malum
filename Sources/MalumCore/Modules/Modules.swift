/// Every module Malum has. The app runs them, and `malum run` and the docs tool read their schemas,
/// so they all take them from here.
@MainActor
public enum Modules {
    /// Every module's schema, by the module's id, without building the modules.
    public static let schemas: [String: ConfigSchema] = [KeyboardConfig.module: KeyboardModule.configSchema]

    /// Builds every module, in the order they're started, with what they need from the app. Building
    /// one starts nothing.
    public static func all(
        files: any FileSystem, paths: Paths, keyboard: KeyboardSystem, log: Log
    ) -> [any Module] {
        [KeyboardModule(files: files, paths: paths, system: keyboard, log: log)]
    }
}
