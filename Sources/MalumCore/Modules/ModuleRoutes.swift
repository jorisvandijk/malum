/// Where shortcuts go between modules: what each module offers the hotkey registry, which modules
/// are switched on, and running a caught shortcut on the module that handles it.
///
/// The keyboard module reads it to build its registry and hands it every shortcut the tap catches.
/// `ModuleSwitch` keeps `switchedOn` up to date.
@MainActor
public final class ModuleRoutes {
    /// A module the routes know without keeping it alive, since modules hold the routes.
    private struct Entry {
        /// The module, gone once nothing else holds it.
        weak var module: (any Module)?
    }

    /// Every module, by id.
    private var entries: [String: Entry] = [:]
    /// The modules `malum.toml` switches on, whether or not they run yet.
    public private(set) var switchedOn: Set<String> = []

    /// Creates routes that know no modules yet.
    public init() {}

    /// What each module offers, by id.
    var offers: [String: HotkeyOffer] {
        entries.compactMapValues { $0.module?.hotkeys }
    }

    /// Learns `modules`, so shortcuts can reach them.
    func add(_ modules: [any Module]) {
        for module in modules {
            entries[module.id] = Entry(module: module)
        }
    }

    /// Takes `modules` as the switched-on ones, and says whether that changed anything.
    func switchOn(_ modules: Set<String>) -> Bool {
        guard modules != switchedOn else { return false }
        switchedOn = modules
        return true
    }

    /// Opens the app with `bundleID` through a running module that opens apps, such as the window
    /// manager, so it's raised as its shortcut would. Says whether one took it.
    func openApp(_ bundleID: String) -> Bool {
        let opener = entries.values.compactMap(\.module).first { $0.hotkeys.opensApps && $0.status.isActive }
        guard let opener else { return false }
        opener.perform(.app(bundleID))
        return true
    }

    /// Runs the action called `action` on the running module that offers it, as a shortcut bound
    /// to it would. Says whether one ran it.
    public func run(actionNamed action: String) -> Bool {
        let offering = entries.values.compactMap(\.module).first { $0.hotkeys.actions.contains(action) }
        guard let module = offering, module.status.isActive else { return false }
        module.perform(.module(action))
        return true
    }

    /// Runs `target` on its module, only while that module runs. A shortcut for a module that is
    /// starting, waiting or failed does nothing.
    func run(_ target: HotkeyTarget) {
        guard let module = entries[target.module]?.module, module.status.isActive else { return }
        module.perform(target.action)
    }
}
