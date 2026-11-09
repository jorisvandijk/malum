/// A command that asks the running app to run one of its modules' actions, such as `malum screenshot`.
public struct ActionCommand: Sendable {
    /// Where the running app is found.
    private let instance: AppInstance
    /// Where the request waits for the app.
    private let requests: ActionRequests
    /// How the app is told.
    private let signals: any Signals

    /// Creates the command.
    public init(instance: AppInstance, requests: ActionRequests, signals: any Signals) {
        self.instance = instance
        self.requests = requests
        self.signals = signals
    }

    /// Leaves a request for `action` and signals the app, saying what happened. Nothing is left
    /// behind when the app isn't running.
    public func run(_ action: String) -> Message {
        do {
            let processID = try instance.runningProcessID()
            try requests.add(action)
            try signals.askForActions(processID)
            return .askedFor(action)
        } catch {
            return .failed(error)
        }
    }
}
