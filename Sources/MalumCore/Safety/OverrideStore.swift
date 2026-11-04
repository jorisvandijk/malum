import Foundation

/// Keeps the overrides in the state folder, where the app and the command both reach them, so
/// `malum safe` and `malum disable` work whether the app runs or not.
public struct OverrideStore: Sendable {
    /// The file that holds why safe mode is on. Empty or missing means it's off.
    private static let safeModeName = "safe-mode"
    /// The file that lists the disabled modules, one per line.
    private static let disabledName = "disabled"

    /// The state folder.
    private let state: StateFolder

    /// Creates the store in `state`.
    public init(state: StateFolder) {
        self.state = state
    }

    /// The overrides as they're saved now.
    public func read() throws(StateError) -> Overrides {
        let safeMode = try state.read(Self.safeModeName).flatMap(Self.reason)
        let disabled = try state.read(Self.disabledName).map(Self.lines) ?? []
        return Overrides(safeMode: safeMode, disabled: Set(disabled))
    }

    /// Turns safe mode on.
    public func enterSafeMode(_ reason: SafeModeReason) throws(StateError) {
        try state.write("\(reason.rawValue)\n", to: Self.safeModeName)
    }

    /// Turns safe mode off.
    public func leaveSafeMode() throws(StateError) {
        try state.write("", to: Self.safeModeName)
    }

    /// Keeps `module` off.
    public func disable(_ module: String) throws(StateError) {
        try state.update(Self.disabledName) { Self.text(Set(Self.lines($0 ?? "")).union([module])) }
    }

    /// Lets `module` run again when `malum.toml` switches it on.
    public func enable(_ module: String) throws(StateError) {
        try state.update(Self.disabledName) { Self.text(Set(Self.lines($0 ?? "")).subtracting([module])) }
    }

    /// The reason saved in the safe mode file. Text that isn't a known reason still means safe mode
    /// is on, since keeping modules off is the safe way to read it.
    private static func reason(_ text: String) -> SafeModeReason? {
        let saved = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !saved.isEmpty else { return nil }
        return SafeModeReason(rawValue: saved) ?? .asked
    }

    /// The lines of `text` that aren't blank, trimmed.
    private static func lines(_ text: String) -> [String] {
        text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// `modules` as the file holds them: sorted, one per line.
    private static func text(_ modules: Set<String>) -> String {
        modules.sorted().map { "\($0)\n" }.joined()
    }
}
