/// The times Malum started lately, to spot a crash at startup that has launchd restart it over and over.
///
/// Quitting from the menu forgets them, so opening and quitting Malum a few times isn't taken for a crash.
public struct LaunchRecord: Sendable {
    /// How many starts within the window put Malum in safe mode.
    public static let limit = 3
    /// How long the window is, in minutes.
    public static let windowMinutes = 2
    /// Seconds in a minute.
    private static let secondsPerMinute = 60
    /// The file that holds the start times, in whole seconds since 1970, one per line.
    private static let name = "launches"

    /// The state folder.
    private let state: StateFolder

    /// Creates the record in `state`.
    public init(state: StateFolder) {
        self.state = state
    }

    /// Writes down a start at `now`, in seconds since 1970, and says whether it makes `limit`
    /// starts within the window. Older starts are dropped.
    public func record(at now: Int) throws(StateError) -> Bool {
        let window = Self.windowMinutes * Self.secondsPerMinute
        var count = 0
        try state.update(Self.name) { text in
            let recent = (text ?? "").split(separator: "\n").compactMap { Int($0) }
                .filter { $0 <= now && now - $0 < window }
            count = recent.count + 1
            return (recent + [now]).map { "\($0)\n" }.joined()
        }
        return count >= Self.limit
    }

    /// Forgets every start, as a clean quit does.
    public func clear() throws(StateError) {
        try state.write("", to: Self.name)
    }
}
