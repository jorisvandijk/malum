/// `malum reload`: asks the running app to reload.
public struct ReloadCommand: Sendable {
    /// Where the running app is found.
    private let instance: AppInstance
    /// How the app is told.
    private let signals: any Signals

    /// Creates the command.
    public init(instance: AppInstance, signals: any Signals) {
        self.instance = instance
        self.signals = signals
    }

    /// Sends the app `SIGHUP` and says what happened.
    public func run() -> Message {
        do {
            try signals.hangUp(instance.runningProcessID())
            return Message(.info, "asked \(Project.name) to reload")
        } catch {
            return Message(.error, error.description)
        }
    }
}
