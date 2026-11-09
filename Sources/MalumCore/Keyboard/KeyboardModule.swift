import Observation

/// The keyboard module: the hyper key, the key remaps and the shortcuts from `keyboard.toml`.
///
/// It opens no apps and runs no actions itself. It hands each shortcut to the module that offers
/// it, and warns about shortcuts nothing handles, such as an app's bundle ID before the window
/// manager is there.
@Observable
@MainActor
final class KeyboardModule: Module {
    /// Its settings: none in `malum.toml` besides the switch, and `keyboard.toml` checked as a whole.
    static let configSchema = ConfigSchema(
        about: "The hyper key, key remaps and shortcuts, set in `\(Paths.moduleTOMLName(KeyboardConfig.module))`. "
            + "See [keyboard](keyboard.md).",
        settings: [:], fileCheck: .keyboard)

    /// The module's id, which names `keyboard.toml`.
    let id = KeyboardConfig.module
    /// A tap that changes key events needs Accessibility, and nothing else.
    let permissions: Set<Permission> = [.accessibility]
    /// Its settings.
    var schema: ConfigSchema { Self.configSchema }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// Sets and undoes the hyper key and the remaps.
    @ObservationIgnored private let remapper: KeyRemapper
    /// Catches the keys.
    @ObservationIgnored private let keyCatcher: any KeyCatcher
    /// Tells what keeps keys from reaching the tap, such as secure input.
    @ObservationIgnored private let state: any KeyboardState
    /// The other modules' offers, and where caught shortcuts go.
    @ObservationIgnored private let routes: ModuleRoutes
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The settings last read without errors.
    @ObservationIgnored private var config = KeyboardConfig()
    /// The lines of `keyboard.toml` that `config` was read from, for the registry's problems.
    @ObservationIgnored private var lines = TOMLLines("")
    /// Where the shortcuts of `config` go.
    @ObservationIgnored private var registry = HotkeyRegistry(
        bindings: [], offers: [:], switchedOn: [], lines: TOMLLines(""))
    /// Whether the module runs, so new settings are put to work straight away.
    @ObservationIgnored private var isStarted = false
    /// The last restart asked for. Each one waits for the one before it, so `stop` waits for them all.
    @ObservationIgnored private var restart: Task<Void, Never>?
    /// Hands the shortcuts the running tap catches to `routes`.
    @ObservationIgnored private var listener: Task<Void, Never>?

    /// Creates the module, off, working through `system`, sending shortcuts through `routes` and
    /// logging to `log`.
    init(system: KeyboardSystem, routes: ModuleRoutes, log: Log) {
        self.routes = routes
        remapper = system.remapper
        keyCatcher = system.keyCatcher
        state = system.state
        self.log = log.module(KeyboardConfig.module)
    }

    /// Undoes the remaps a crash left behind.
    func cleanUp() async throws {
        try await remapper.clear()
    }

    /// Takes `keyboard.toml` as the config checked it, and puts it to work when the module runs. No
    /// file means no hyper key, remaps or shortcuts.
    func apply(_ settings: ModuleSettings) {
        let text = settings.file ?? ""
        // The config only hands over text that reads without errors, so this never falls back.
        config = KeyboardConfig.read(text).config ?? KeyboardConfig()
        lines = TOMLLines(text)
        register()
    }

    /// Sends the shortcuts to the modules that are switched on now.
    func modulesSwitched() {
        register()
    }

    /// Catches keys, then sets the hyper key and the remaps.
    func start() async throws {
        status = .starting
        do {
            try await catchKeys()
        } catch {
            fail(error)
            throw error
        }
        isStarted = true
    }

    /// Stops catching keys and undoes the remaps.
    func stop() async {
        while let pending = restart {
            await pending.value
            if restart == pending {
                restart = nil
            }
        }
        isStarted = false
        keyCatcher.stop()
        listener?.cancel()
        listener = nil
        await clearRemaps()
        status = .off
    }

    /// Shows in the status what keeps keys from working now, such as secure input. Starts the tap
    /// again when macOS switched it off, which happens when Accessibility is taken away and given back
    /// between two checks.
    func check() {
        guard isStarted, status.isActive else { return }
        guard keyCatcher.isRunning else {
            log.report(.warning(KeyboardError.tapSwitchedOff))
            queueRestart()
            return
        }
        showStatus()
    }

    /// Starts the tap again and sets the remaps again, which a keyboard plugged in doesn't have yet.
    func resume() async {
        guard isStarted else { return }
        queueRestart()
        await restart?.value
    }

    /// Starts the tap with the current settings, then sets the remaps. The tap goes first, so a
    /// refused tap never leaves the hyper key typing as a key nothing catches.
    private func catchKeys() async throws {
        let session = TapSession(registry: registry, hyperKey: config.hyperKey)
        guard keyCatcher.start(session) else {
            throw KeyboardError.tapRefused
        }
        listen(to: session)
        do {
            try await remapper.apply(KeyMapping(config))
        } catch {
            keyCatcher.stop()
            throw error
        }
        showStatus()
    }

    /// Shows what keeps keys from working, worst first: secure input, a Modifier Keys swap of the hyper
    /// key, then the first problem in the bindings.
    private func showStatus() {
        let reason = blocker ?? registry.problems.first?.message.text
        let shown = reason.map { ModuleStatus.degraded(reason: $0.description) } ?? .running
        guard shown != status else { return }
        status = shown
    }

    /// What keeps keys from reaching Malum now, or nil when nothing does.
    private var blocker: MessageText? {
        if case .on(let app) = state.secureInput {
            return .secureInput(in: app)
        }
        guard let hyperKey = config.hyperKey, KeyMapping.isSwapped(hyperKey, in: state.modifierSwaps) else {
            return nil
        }
        return .hyperKeySwapped(hyperKey)
    }

    /// Builds the registry from the settings and the other modules' offers, logs its problems, and
    /// puts it to work when the module runs.
    private func register() {
        registry = HotkeyRegistry(
            bindings: config.bindings, offers: routes.offers, switchedOn: routes.switchedOn, lines: lines)
        for problem in registry.problems {
            log.report(problem.message)
        }
        guard isStarted else { return }
        queueRestart()
    }

    /// Hands every shortcut `session` catches to the module that handles it, until the session ends.
    private func listen(to session: TapSession) {
        listener?.cancel()
        listener = Task { [weak self] in
            for await target in session.actions {
                self?.routes.run(target)
            }
        }
    }

    /// Restarts the tap once the restart before it has finished.
    private func queueRestart() {
        let previous = restart
        restart = Task { [weak self] in
            await previous?.value
            await self?.restartTap()
        }
    }

    /// Puts new settings to work while the module runs. When that fails, the remaps are undone too,
    /// so the hyper key never types as a key that nothing catches.
    private func restartTap() async {
        guard isStarted else { return }
        do {
            try await catchKeys()
        } catch {
            await clearRemaps()
            fail(error)
        }
    }

    /// Undoes the remaps, logging when that fails.
    private func clearRemaps() async {
        do {
            try await remapper.clear()
        } catch {
            log.report(.warning(error))
        }
    }

    /// Shows that the module failed because of `error`.
    private func fail(_ error: any Error) {
        status = .failed(reason: MessageText(error: error).description)
    }
}
