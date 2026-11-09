/// Sets and undoes Malum's key remaps through `hidutil`.
///
/// Remaps last until they're undone, even when Malum is gone. A marker in the state folder says
/// Malum has some set, so the cleanup at the next launch undoes a remap left by a crash, and Malum
/// never clears a mapping it didn't set.
struct KeyRemapper: Sendable {
    /// The marker, which holds the mapping last set. Empty or missing means none is.
    static let markerName = "key-remap"

    /// Runs `hidutil`.
    private let runner: any CommandRunner
    /// Where the marker is kept.
    private let state: StateFolder

    /// Creates the remapper, running `hidutil` through `runner` and marking in `state`.
    init(runner: any CommandRunner, state: StateFolder) {
        self.runner = runner
        self.state = state
    }

    /// Replaces Malum's remaps with `mapping`, or undoes them when it remaps nothing. The marker is
    /// written first, so a crash in between still leaves a trace.
    func apply(_ mapping: KeyMapping) async throws(KeyRemapError) {
        guard mapping != .none else {
            try await clear()
            return
        }
        try mark(mapping.json)
        let result = await runner.run(Hidutil.set(mapping))
        guard result.succeeded else { throw .unset(reason: result.reason) }
    }

    /// Undoes Malum's remaps when the marker says some are set, such as at launch after a crash.
    /// The marker stays when `hidutil` fails, so the next cleanup tries again.
    func clear() async throws(KeyRemapError) {
        guard try isMarked() else { return }
        let result = await runner.run(Hidutil.set(.none))
        guard result.succeeded else { throw .uncleared(reason: result.reason) }
        try mark("")
    }

    /// Whether the marker says remaps are set.
    private func isMarked() throws(KeyRemapError) -> Bool {
        do {
            return try !(state.read(Self.markerName) ?? "").isEmpty
        } catch {
            throw .marker(error)
        }
    }

    /// Writes `text` to the marker.
    private func mark(_ text: String) throws(KeyRemapError) {
        do {
            try state.write(text, to: Self.markerName)
        } catch {
            throw .marker(error)
        }
    }
}
