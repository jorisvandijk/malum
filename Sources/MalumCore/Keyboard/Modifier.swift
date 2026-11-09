/// One of the four modifiers a table of shortcuts in `keyboard.toml` is named after.
///
/// The cases are in the order a table joins them, such as `[ctrl_shift]`.
public enum Modifier: String, CaseIterable, Sendable {
    /// Control.
    case ctrl
    /// Option.
    case option
    /// Command.
    case cmd
    /// Shift.
    case shift

    /// The name of the table that holds every modifier, which the hyper key holds down.
    static let hyperTable = "hyper"
    /// What joins the modifiers in a table's name.
    private static let joiner: Character = "_"

    /// The name of the table of shortcuts that hold `modifiers`, such as `ctrl_shift`, or `hyper` for all four.
    static func table(of modifiers: Set<Modifier>) -> String {
        names(of: modifiers).joined(separator: String(joiner))
    }

    /// The names of `modifiers` in their order, or just `hyper` for all four.
    static func names(of modifiers: Set<Modifier>) -> [String] {
        guard modifiers.count < allCases.count else { return [hyperTable] }
        return allCases.filter(modifiers.contains).map(\.rawValue)
    }

    /// The modifiers a table named `name` holds, in any order, or nil when the name isn't modifiers
    /// joined by `_`, each once.
    static func modifiers(inTable name: String) -> Set<Modifier>? {
        guard name != hyperTable else { return Set(allCases) }
        let words = name.split(separator: joiner, omittingEmptySubsequences: false)
        let modifiers = words.compactMap { Modifier(rawValue: String($0)) }
        guard modifiers.count == words.count, Set(modifiers).count == modifiers.count else { return nil }
        return Set(modifiers)
    }
}
