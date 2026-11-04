/// `malum safe` and `malum disable <module>`: save an override in the state folder, then ask a
/// running app to reload so it takes effect straight away.
public struct OverrideCommand: Sendable {
    /// Where the overrides go.
    private let store: OverrideStore
    /// Where the running app is found.
    private let instance: AppInstance
    /// How the app is told.
    private let signals: any Signals

    /// Creates the command.
    public init(store: OverrideStore, instance: AppInstance, signals: any Signals) {
        self.store = store
        self.instance = instance
        self.signals = signals
    }

    /// Turns safe mode on and says what happened.
    public func safe() -> [Message] {
        do {
            try store.enterSafeMode(.asked)
        } catch {
            return [Message(.error, error.text)]
        }
        return [Message(.info, "safe mode is on: every module stays off until you leave it from the menu bar")]
            + tellApp()
    }

    /// Keeps `module` off and says what happened.
    public func disable(_ module: String) -> [Message] {
        do {
            try store.disable(module)
        } catch {
            return [Message(.error, error.text)]
        }
        return [Message(.info, "\(module) stays off until you enable it from the menu bar")] + tellApp()
    }

    /// Asks the running app to reload. When it isn't running, the override waits for its next start.
    private func tellApp() -> [Message] {
        do {
            try signals.hangUp(instance.runningProcessID())
        } catch {
            guard error == .notRunning else { return [Message(.error, error.text)] }
            return [Message(.info, "\(Project.name) isn't running, so this takes effect when it starts")]
        }
        return [Message(.info, "asked \(Project.name) to reload")]
    }
}
