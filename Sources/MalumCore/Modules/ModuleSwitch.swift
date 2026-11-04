/// Starts and stops the modules as `malum.toml` switches them on and off, and hands running
/// modules their new settings.
@MainActor
public final class ModuleSwitch {
    /// Every module, in the order they're started.
    private let modules: [any Module]
    /// The modules that started and haven't been stopped since.
    public private(set) var started: Set<String> = []
    /// The modules the last update switched on, so a module that failed to start is tried again
    /// only when its table changes.
    private var switchedOn: Set<String> = []
    /// The update still running, so the next one waits for it.
    private var current: Task<[Message], Never>?

    /// Creates a switch for `modules`, with every module off.
    public init(modules: [any Module]) {
        self.modules = modules
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
        enabled: Set<String>, settings: [String: ConfigTable], changed: Set<String>
    ) async -> [Message] {
        await enqueue { await $0.run(enabled: enabled, settings: settings, changed: changed) }
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
                messages.append(Message(.warn, "couldn't clean up after \(module.id): \(error)"))
            }
        }
        return messages
    }

    /// One update, after the one before it has finished.
    private func run(enabled: Set<String>, settings: [String: ConfigTable], changed: Set<String>) async -> [Message] {
        var messages: [Message] = []
        for module in modules {
            let table = settings[module.id] ?? [:]
            let isNew = !switchedOn.contains(module.id) || changed.contains(module.id)
            switch (enabled.contains(module.id), started.contains(module.id)) {
            case (true, false) where isNew:
                messages.append(await start(module, with: table))
            case (true, true) where changed.contains(module.id):
                messages += apply(table, to: module)
            case (false, true):
                await module.stop()
                started.remove(module.id)
                messages.append(Message(.info, "stopped \(module.id)"))
            default:
                break
            }
        }
        switchedOn = enabled
        return messages
    }

    /// Gives `module` its settings, then starts it.
    private func start(_ module: any Module, with table: ConfigTable) async -> Message {
        do {
            try module.apply(table)
            try await module.start()
        } catch {
            return Message(.error, "couldn't start \(module.id): \(error)")
        }
        started.insert(module.id)
        return Message(.info, "started \(module.id)")
    }

    /// Gives a running module its new settings, saying so only when it couldn't take them.
    private func apply(_ table: ConfigTable, to module: any Module) -> [Message] {
        do {
            try module.apply(table)
        } catch {
            return [Message(.error, "couldn't apply \(module.id) settings: \(error)")]
        }
        return []
    }
}
