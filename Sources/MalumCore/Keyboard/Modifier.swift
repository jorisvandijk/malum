/// One of the four modifiers a shortcut holds down, such as `ctrl` in `ctrl+cmd+h`.
///
/// The cases are in the order a shortcut is written in the shared syntax, such as `ctrl+shift+k`.
public enum Modifier: String, CaseIterable, Sendable {
    /// Control.
    case ctrl
    /// Option.
    case option
    /// Command.
    case cmd
    /// Shift.
    case shift

    /// The word for all four modifiers together, which the hyper key holds down.
    static let hyper = "hyper"

    /// The names of `modifiers` in their order, or just `hyper` for all four.
    static func names(of modifiers: Set<Modifier>) -> [String] {
        guard modifiers.count < allCases.count else { return [hyper] }
        return allCases.filter(modifiers.contains).map(\.rawValue)
    }
}
