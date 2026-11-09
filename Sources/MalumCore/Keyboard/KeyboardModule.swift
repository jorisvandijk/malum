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
        about: "The hyper key, key remaps and shortcuts, set in `keyboard.toml`. See [keyboard](keyboard.md).",
        settings: [:], fileCheck: .keyboard)

    /// The module's id, which names `keyboard.toml`.
    let id = KeyboardConfig.module
    /// A tap that changes key events needs Accessibility, and nothing else.
    let permissions: Set<Permission> = [.accessibility]
    /// Its settings.
    var schema: ConfigSchema { Self.configSchema }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// The disk, where `keyboard.toml` is read from.
    @ObservationIgnored private let files: any FileSystem
    /// Where dots is recorded.
    @ObservationIgnored private let paths: Paths
    /// Sets and undoes the hyper key and the remaps.
    @ObservationIgnored private let remapper: KeyRemapper
    /// Catches the keys.
    @ObservationIgnored private let keyCatcher: any KeyCatcher
    /// Tells what keeps keys from reaching the tap, such as secure input.
    @ObservationIgnored private let state: any KeyboardState
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The settings last read without errors.
    @ObservationIgnored private var config = KeyboardConfig()
    /// Where the shortcuts of `config` go.
    @ObservationIgnored private var registry = HotkeyRegistry(
        bindings: [], offers: [:], switchedOn: [], lines: TOMLLines(""))
    /// Whether the module runs, so new settings are put to work straight away.
    @ObservationIgnored private var isStarted = false
    /// New settings being put to work, which `stop` waits for.
    @ObservationIgnored private var restart: Task<Void, Never>?

    /// Creates the module, off, reading `keyboard.toml` through `files` and logging to `log`.
    init(
        files: any FileSystem, paths: Paths, remapper: KeyRemapper, keyCatcher: any KeyCatcher,
        state: any KeyboardState, log: Log
    ) {
        self.files = files
        self.paths = paths
        self.remapper = remapper
        self.keyCatcher = keyCatcher
        self.state = state
        self.log = log.module(KeyboardConfig.module)
    }

    /// Undoes the remaps a crash left behind.
    func cleanUp() async throws {
        try await remapper.clear()
    }

    /// Reads `keyboard.toml` again, which the config has already checked, and puts it to work when
    /// the module runs. The table holds nothing besides the switch.
    func apply(_: ConfigTable) throws {
        let text = try readFile()
        guard let config = KeyboardConfig.read(text).config else {
            throw ConfigProblem(.error, .fixFirst(Paths.moduleTOMLName(id)))
        }
        self.config = config
        // TODO: every module's offer and which are on, once a module offers actions (the window manager).
        registry = HotkeyRegistry(bindings: config.bindings, offers: [:], switchedOn: [], lines: TOMLLines(text))
        for problem in registry.problems {
            log.report(problem.message)
        }
        guard isStarted else { return }
        restart = Task { [weak self] in await self?.restartTap() }
    }

    /// Catches keys, then sets the hyper key and the remaps.
    func start() async throws {
        status = .starting
        do {
            try await catchKeys()
        } catch {
            status = .failed(reason: MessageText(error: error).description)
            throw error
        }
        isStarted = true
    }

    /// Stops catching keys and undoes the remaps.
    func stop() async {
        await restart?.value
        restart = nil
        isStarted = false
        keyCatcher.stop()
        do {
            try await remapper.clear()
        } catch {
            log.report(.warning(error))
        }
        status = .off
    }

    /// Shows in the status what keeps keys from working now, such as secure input.
    func check() {
        guard isStarted, status.isActive else { return }
        showStatus()
    }

    /// Starts the tap again and sets the remaps again, which a keyboard plugged in doesn't have yet.
    func resume() async {
        await restart?.value
        guard isStarted else { return }
        await restartTap()
    }

    /// Starts the tap with the current settings, then sets the remaps. The tap goes first, so a
    /// refused tap never leaves the hyper key typing as a key nothing catches.
    private func catchKeys() async throws {
        // TODO: run the shortcuts that come out on the session's actions, once a module offers actions.
        guard keyCatcher.start(TapSession(registry: registry, hyperKey: config.hyperKey)) else {
            throw KeyboardError.tapRefused
        }
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

    /// Puts new settings to work while the module runs.
    private func restartTap() async {
        do {
            try await catchKeys()
        } catch {
            status = .failed(reason: MessageText(error: error).description)
        }
    }

    /// The text of `keyboard.toml`, empty when dots isn't known or the file isn't there.
    private func readFile() throws -> String {
        guard let dots = try DotsPointer(files: files, paths: paths).read() else { return "" }
        return try files.text(ifFileAt: paths.moduleTOML(id, in: dots)) ?? ""
    }
}
