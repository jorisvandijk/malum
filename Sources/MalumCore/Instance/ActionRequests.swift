/// The actions a command asked the running app for, such as `screenshot`, waiting in the state
/// folder until the app takes them after `SIGUSR1`.
public struct ActionRequests: Sendable {
    /// The file the requests wait in, one action per line.
    private static let fileName = "action-requests"
    /// Where the file lives.
    private let state: StateFolder

    /// Creates the requests kept in `state`.
    public init(state: StateFolder) {
        self.state = state
    }

    /// Adds a request for `action`.
    public func add(_ action: String) throws(StateError) {
        try state.update(Self.fileName) { ($0 ?? "") + action + "\n" }
    }

    /// The waiting actions, oldest first, which are then no longer waiting.
    public func take() throws(StateError) -> [String] {
        var taken: [String] = []
        try state.update(Self.fileName) { text in
            taken = (text ?? "").split(separator: "\n").map(String.init)
            return taken.isEmpty ? nil : ""
        }
        return taken
    }
}
