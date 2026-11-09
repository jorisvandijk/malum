/// Starts and stops the modules as `malum.toml` switches them on and off, and hands running
/// modules their new settings. A module that's missing a permission waits until it's granted.
@MainActor
public final class ModuleSwitch {
    /// Every module, in the order they're started.
    private let modules: [any Module]
    /// Tells which permissions Malum has.
    private let permissions: any PermissionCheck
    /// Where shortcuts go, told which modules are switched on.
    private let routes: ModuleRoutes
    /// The modules that started and haven't been stopped since.
    public private(set) var started: Set<String> = []
    /// The modules the last update switched on, so a module that failed to start is tried again
    /// only when its table changes.
    private var switchedOn: Set<String> = []
    /// The settings the last update gave, for starting a module once its permissions are granted.
    private var lastSettings: [String: ModuleSettings] = [:]
    /// The switched-on modules that wait for permissions, with the ones they're missing.
    public private(set) var waiting: [String: Set<Permission>] = [:]
    /// The update still running, so the next one waits for it.
    private var current: Task<[Message], Never>?

    /// Creates a switch for `modules`, with every module off, that checks their permissions with
    /// `permissions` and keeps `routes` up to date.
    public init(modules: [any Module], permissions: any PermissionCheck, routes: ModuleRoutes) {
        self.modules = modules
        self.permissions = permissions
        self.routes = routes
        routes.add(modules)
    }

    /// Has every module undo what an earlier run may have left behind, and says what failed. Runs in
    /// line with the updates, so a module never starts before its cleanup is done.
    public func cleanUp() async -> [Message] {
        await enqueue { await $0.cleanUpAll() }
    }

    /// Switches each module on or off as `enabled` says, gives running modules whose settings
    /// `changed` their new settings, and says what it did. Updates run one at a time, in the order
    /// they're asked for.
    public func update(
        enabled: Set<String>, settings: [String: ModuleSettings], changed: Set<String>
    ) async -> [Message] {
        await enqueue { await $0.run(enabled: enabled, settings: settings, changed: changed) }
    }

    /// Stops the running modules that lost a permission, so they wait for it again, starts the waiting
    /// modules whose permissions were granted since, and has the others check what macOS doesn't
    /// announce. Says what it did.
    public func recheck() async -> [Message] {
        await enqueue { await $0.recheckAll() }
    }

    /// Has the running modules set up again what macOS may have dropped, and says which did.
    public func resume() async -> [Message] {
        await enqueue { switcher in
            var messages: [Message] = []
            for module in switcher.modules where switcher.started.contains(module.id) {
                await module.resume()
                messages.append(.resumed(module.id))
            }
            return messages
        }
    }

    /// Runs `work` once everything asked for before it has finished.
    private func enqueue(_ work: @escaping @Sendable @MainActor (ModuleSwitch) async -> [Message]) async -> [Message] {
        let previous = current
        let task = Task { [weak self] in
            _ = await previous?.value
            guard let self else { return [Message]() }
            return await work(self)
        }
        current = task
        return await task.value
    }

    /// Every module's cleanup, in order. A cleanup that fails doesn't stop the others.
    private func cleanUpAll() async -> [Message] {
        var messages: [Message] = []
        for module in modules {
            do {
                try await module.cleanUp()
            } catch {
                messages.append(.cleanUpFailed(module.id, error))
            }
        }
        return messages
    }

    /// Stops each running module that lost a permission and has the others check, then retries the
    /// waiting ones.
    private func recheckAll() async -> [Message] {
        var messages: [Message] = []
        for module in modules where started.contains(module.id) {
            let missing = permissions.missing(from: module.permissions)
            guard missing.isEmpty else {
                await module.stop()
                started.remove(module.id)
                messages += [.stopped(module.id)] + wait(module.id, for: missing)
                continue
            }
            module.check()
        }
        return messages + (await retry())
    }

    /// Runs the last update again when a waiting module's missing permissions have changed.
    private func retry() async -> [Message] {
        guard waiting.contains(where: { permissions.missing(from: $0.value) != $0.value }) else { return [] }
        return await run(enabled: switchedOn, settings: lastSettings, changed: [])
    }

    /// One update, after the one before it has finished.
    private func run(enabled: Set<String>, settings: [String: ModuleSettings], changed: Set<String>) async -> [Message]
    {
        lastSettings = settings
        let offers = routes.offers
        if routes.switchOn(enabled) {
            // A module being switched off now is stopped below, so only the ones that stay on hear it.
            for module in modules where started.contains(module.id) && enabled.contains(module.id) {
                module.modulesSwitched()
            }
        }
        var messages: [Message] = []
        for module in modules {
            let given = settings[module.id] ?? ModuleSettings()
            let isNew =
                !switchedOn.contains(module.id) || changed.contains(module.id) || waiting[module.id] != nil
            switch (enabled.contains(module.id), started.contains(module.id)) {
            case (true, false) where isNew:
                messages += await start(module, with: given)
            case (true, true) where changed.contains(module.id):
                messages += apply(given, to: module)
            case (false, true):
                await module.stop()
                started.remove(module.id)
                messages.append(.stopped(module.id))
            case (false, false):
                waiting[module.id] = nil
            default:
                break
            }
        }
        switchedOn = enabled
        if routes.offers != offers {
            // New settings changed what a module offers, such as the keys it claims.
            for module in modules where started.contains(module.id) {
                module.modulesSwitched()
            }
        }
        return messages
    }

    /// Gives `module` its settings, then starts it, once it has every permission it needs.
    private func start(_ module: any Module, with settings: ModuleSettings) async -> [Message] {
        let missing = permissions.missing(from: module.permissions)
        guard missing.isEmpty else { return wait(module.id, for: missing) }
        waiting[module.id] = nil
        do {
            try module.apply(settings)
            try await module.start()
        } catch {
            return [.startFailed(module.id, error)]
        }
        started.insert(module.id)
        return [.started(module.id)]
    }

    /// Keeps the module `id` waiting for `missing`, saying so only when that's news.
    private func wait(_ id: String, for missing: Set<Permission>) -> [Message] {
        guard waiting[id] != missing else { return [] }
        waiting[id] = missing
        return [.waiting(id, for: missing)]
    }

    /// Gives a running module its new settings, saying so only when it couldn't take them.
    private func apply(_ settings: ModuleSettings, to module: any Module) -> [Message] {
        do {
            try module.apply(settings)
        } catch {
            return [.applyFailed(module.id, error)]
        }
        return []
    }
}
