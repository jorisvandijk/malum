import AppKit
import Carbon.HIToolbox
import CoreGraphics
import MalumCore

/// What macOS says about the keyboard right now: secure input, and the key swaps set per keyboard
/// under Modifier Keys in System Settings.
@MainActor
public final class SystemKeyboardState {
    /// The key of the login session's dictionary that holds the process that turned secure input on.
    private static let secureInputProcess = "kCGSSessionSecureInputPID"
    /// How the global preference keys start that hold one keyboard's Modifier Keys swaps each.
    private static let swapPrefix = "com.apple.keyboard.modifiermapping."
    /// The global preferences, written out because the framework's constants aren't safe to read
    /// under strict concurrency.
    private static let anyApplication = "kCFPreferencesAnyApplication" as CFString
    /// This user's preferences.
    private static let currentUser = "kCFPreferencesCurrentUser" as CFString
    /// This Mac's preferences, where `defaults -currentHost` reads.
    private static let currentHost = "kCFPreferencesCurrentHost" as CFString

    /// Reads the state as it is each time it's asked.
    public init() {}
}

// MARK: - KeyboardState

extension SystemKeyboardState: KeyboardState {
    /// Whether secure input is on, and the name of the app that turned it on.
    public var secureInput: SecureInput {
        guard IsSecureEventInputEnabled() else { return .off }
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        let process = session?[Self.secureInputProcess] as? pid_t
        return .on(app: process.flatMap { NSRunningApplication(processIdentifier: $0)?.localizedName })
    }

    /// Every keyboard's Modifier Keys swaps, read fresh, since System Settings changes them from
    /// another process.
    public var modifierSwaps: [[String: UInt64]] {
        let (app, user, host) = (Self.anyApplication, Self.currentUser, Self.currentHost)
        CFPreferencesSynchronize(app, user, host)
        let keys = CFPreferencesCopyKeyList(app, user, host) as? [String] ?? []
        return keys.filter { $0.hasPrefix(Self.swapPrefix) }.flatMap { key in
            let swaps = CFPreferencesCopyValue(key as CFString, app, user, host) as? [[String: Any]] ?? []
            return swaps.map { swap in swap.compactMapValues { ($0 as? NSNumber)?.uint64Value } }
        }
    }
}
