/// Which module each shortcut goes to: the keys switched-on modules claim for themselves, and the
/// shortcuts from `keyboard.toml` that a switched-on module handles.
///
/// Every module's keys go through it, so a key is only ever one module's. A clash, or a shortcut
/// nothing handles, is left out and reported, at its line in `keyboard.toml` when it has one.
struct HotkeyRegistry: Sendable {
    /// What's wrong, in the order of the lines in `keyboard.toml`, those without a line last.
    let problems: [ConfigProblem]
    /// Where each registered shortcut goes.
    private let targets: [Hotkey: HotkeyTarget]

    /// Registers `bindings`, read from `keyboard.toml` with `lines` its lines, for the modules in
    /// `offers`, by id. Only the modules in `switchedOn` get keys.
    init(bindings: [KeyBinding], offers: [String: HotkeyOffer], switchedOn: Set<String>, lines: TOMLLines) {
        var builder = Builder(switchedOn: switchedOn, lines: lines)
        for (module, offer) in offers.sorted(by: { $0.key < $1.key }) {
            builder.take(offer, from: module)
        }
        for binding in bindings {
            builder.register(binding)
        }
        builder.reportIdleBindings()
        targets = builder.targets
        problems = ConfigProblem.byLine(builder.problems)
    }

    /// Where `hotkey` goes, or nil when no module has it.
    func target(for hotkey: Hotkey) -> HotkeyTarget? {
        targets[hotkey]
    }
}

extension HotkeyRegistry {
    /// The registry while it's being built.
    private struct Builder {
        /// The file the shortcuts are read from.
        private static let file = Paths.moduleTOMLName(KeyboardConfig.module)

        /// The modules that are switched on.
        private let switchedOn: Set<String>
        /// The line each key of `keyboard.toml` is on.
        private let lines: TOMLLines
        /// The module that has each claim.
        private var owners: [HotkeyClaim: String] = [:]
        /// The first shortcut of each switched-off module, which the warning about it points to.
        private var firstIdle: [String: [String]] = [:]
        /// The first shortcut to an app when no module opens apps.
        private var firstUnopenedApp: [String]?
        /// Where each shortcut registered so far goes.
        private(set) var targets: [Hotkey: HotkeyTarget] = [:]
        /// What's wrong so far.
        private(set) var problems: [ConfigProblem] = []

        /// Starts with nothing registered.
        init(switchedOn: Set<String>, lines: TOMLLines) {
            self.switchedOn = switchedOn
            self.lines = lines
        }

        /// Gives `module` the actions and the opening of apps in `offer`, and its fixed keys when
        /// it's switched on.
        mutating func take(_ offer: HotkeyOffer, from module: String) {
            for action in offer.actions.sorted() {
                claim(.action(action), by: module)
            }
            if offer.opensApps {
                claim(.apps, by: module)
            }
            guard switchedOn.contains(module) else { return }
            for (hotkey, action) in offer.fixedKeys.sorted(by: { $0.key.description < $1.key.description }) {
                guard claim(.key(hotkey), by: module) else { continue }
                targets[hotkey] = HotkeyTarget(module: module, action: .module(action))
            }
        }

        /// Sends `binding` to the module that handles it, or reports why it can't.
        mutating func register(_ binding: KeyBinding) {
            if let owner = owners[.key(binding.hotkey)] {
                let path = TableReader.dotted(binding.path)
                add(.error, at: binding.path, .hotkeyTaken(path, binding.hotkey.description, owner))
                return
            }
            guard let module = handler(of: binding) else { return }
            guard switchedOn.contains(module) else {
                firstIdle[module] = firstIdle[module] ?? binding.path
                return
            }
            targets[binding.hotkey] = HotkeyTarget(module: module, action: binding.action)
        }

        /// Warns once for each switched-off module that has shortcuts, and once when shortcuts name
        /// apps but no module opens them.
        mutating func reportIdleBindings() {
            if let path = firstUnopenedApp {
                add(.warn, at: path, .noAppOpener)
            }
            for (module, path) in firstIdle.sorted(by: { $0.key < $1.key }) {
                add(.warn, at: path, .moduleOff(module))
            }
        }

        /// The module that handles `binding`'s action, or nil when none does. A module's action
        /// nobody offers is an error; an app nobody opens is warned about once.
        private mutating func handler(of binding: KeyBinding) -> String? {
            switch binding.action {
            case .module(let name):
                guard let module = owners[.action(name)] else {
                    add(.error, at: binding.path, .unknownAction(TableReader.dotted(binding.path), name))
                    return nil
                }
                return module
            case .app:
                guard let module = owners[.apps] else {
                    firstUnopenedApp = firstUnopenedApp ?? binding.path
                    return nil
                }
                return module
            }
        }

        /// Gives `claim` to `module`, or reports the clash when another module has it. Says whether
        /// `module` got it.
        @discardableResult
        private mutating func claim(_ claim: HotkeyClaim, by module: String) -> Bool {
            if let owner = owners[claim] {
                problems.append(ConfigProblem(.error, file: Self.file, .claimedTwice(claim.description, owner, module)))
                return false
            }
            owners[claim] = module
            return true
        }

        /// Adds a problem of `level` about the shortcut at `path`.
        private mutating func add(_ level: Level, at path: [String], _ text: MessageText) {
            problems.append(ConfigProblem(level, file: Self.file, line: lines.line(of: path), text))
        }
    }
}
