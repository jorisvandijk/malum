/// Every module Malum has. The app runs them, and `malum run` and the docs tool read their schemas,
/// so they all take them from here.
@MainActor
public enum Modules {
    /// Every module's schema, by the module's id, without building the modules.
    public static let schemas: [String: ConfigSchema] = [
        KeyboardConfig.module: KeyboardModule.configSchema, WindowManagerConfig.module: WindowManagerConfig.schema,
        LauncherModule.module: LauncherModule.configSchema, ClipboardConfig.module: ClipboardConfig.schema,
        SambaConfig.module: SambaConfig.schema,
    ]

    /// Builds every module, in the order they're started, with their macOS parts from the app and the
    /// `routes` their shortcuts go through. Building one starts nothing.
    public static func all(_ systems: ModuleSystems, routes: ModuleRoutes, log: Log) -> [any Module] {
        [
            KeyboardModule(system: systems.keyboard, routes: routes, log: log),
            WindowManagerModule(system: systems.windows, log: log),
            LauncherModule(system: systems.launcher, routes: routes, log: log),
            ClipboardModule(system: systems.clipboard, log: log),
        ]
    }
}
