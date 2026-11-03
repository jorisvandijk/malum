import Observation

/// One part of Malum, such as the window manager or the launcher.
///
/// The app and the menu bar treat every module the same way through this protocol. A module that
/// throws fails on its own and shows up in the menu bar as failed; the other modules keep running.
@MainActor
public protocol Module: AnyObject, Observable {
    /// The module's name, which is also the name of its table in `malum.toml`.
    var id: String { get }
    /// The permissions the module needs before it can run.
    var permissions: Set<Permission> { get }
    /// The settings the module takes in its table in `malum.toml`.
    var schema: ConfigSchema { get }
    /// Where the module is now, observed by the menu bar.
    var status: ModuleStatus { get }

    // TODO: the hotkeys the module wants, once the hotkey registry exists.

    /// Starts the module with the settings it was last given.
    func start() async throws
    /// Takes new settings from the module's table in `malum.toml`, without a restart. The table has
    /// already been checked against `schema`.
    func apply(_ config: ConfigTable) throws
    /// Stops the module and undoes whatever it changed system-wide.
    func stop() async
}
