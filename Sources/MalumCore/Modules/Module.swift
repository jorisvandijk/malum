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

    /// The actions the module offers `keyboard.toml`, the keys it claims and whether it opens apps.
    var hotkeys: HotkeyOffer { get }

    /// Undoes whatever an earlier run may have left behind system-wide, such as a key remap after a
    /// crash. Runs at every launch, before any module starts, whether the module is switched on or not.
    func cleanUp() async throws
    /// Starts the module with the settings it was last given.
    func start() async throws
    /// Takes new settings without a restart: its table, and the text of its own file when the settings
    /// are there. Both have already been checked against `schema`, so the module never reads them again.
    func apply(_ settings: ModuleSettings) throws
    /// Stops the module and undoes whatever it changed system-wide.
    func stop() async
    /// Looks again at what macOS doesn't announce, such as secure input. Runs every few seconds while
    /// the module runs.
    func check()
    /// Sets up again what macOS may have dropped while the module ran: after the Mac wakes, the user
    /// switches back to this login, or a keyboard is plugged in.
    func resume() async
}

extension Module {
    /// No actions, no keys and no apps, for a module that has no shortcuts.
    public var hotkeys: HotkeyOffer { HotkeyOffer() }

    /// Nothing to look at, for a module that macOS tells everything it needs.
    public func check() {}

    /// Nothing to set up again, for a module that sets nothing macOS can drop.
    public func resume() async {}
}
