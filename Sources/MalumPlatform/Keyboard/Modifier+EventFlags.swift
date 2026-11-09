import CoreGraphics
import MalumCore

/// The modifiers as a key event carries them.
extension Modifier {
    /// Every modifier's flag.
    private static let allFlags = CGEventFlags(allCases.map(\.flag))

    /// This modifier's flag in a key event.
    var flag: CGEventFlags {
        switch self {
        case .ctrl: .maskControl
        case .option: .maskAlternate
        case .cmd: .maskCommand
        case .shift: .maskShift
        }
    }

    /// The modifiers `flags` holds.
    static func held(in flags: CGEventFlags) -> Set<Modifier> {
        Set(allCases.filter { flags.contains($0.flag) })
    }

    /// `flags` with exactly `modifiers` held, keeping its other flags, such as fn or the keypad's.
    static func flags(_ flags: CGEventFlags, holding modifiers: Set<Modifier>) -> CGEventFlags {
        flags.subtracting(allFlags).union(CGEventFlags(modifiers.map(\.flag)))
    }
}
