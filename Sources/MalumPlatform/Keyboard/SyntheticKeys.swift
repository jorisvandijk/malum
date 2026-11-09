import CoreGraphics
import MalumCore

/// The key events the event tap posts itself: left cmd held down, and the tab that opens the app
/// switcher with it.
///
/// Each one carries `marker`, so the tap lets its own events through untouched.
enum SyntheticKeys {
    /// Marks Malum's own events in their source's user data: "MALM" in ASCII.
    static let marker: Int64 = 0x4D41_4C4D

    /// Whether `event` is one the tap posted itself.
    static func isOwn(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == marker
    }

    /// Holds left cmd down, then presses and lets go of tab with `modifiers`, in that order so the
    /// app switcher sees them that way. The tab is let go straight away, as a held tab makes the
    /// switcher race through the apps.
    static func openSwitcher(_ modifiers: Set<Modifier>) {
        holdCommand(true)
        for down in [true, false] {
            guard let tab = CGEvent(keyboardEventSource: nil, virtualKey: Key.tab.keyCode, keyDown: down) else {
                continue
            }
            tab.flags = Modifier.flags(tab.flags, holding: modifiers)
            post(tab)
        }
    }

    /// Lets go of the cmd `openSwitcher` held, which picks the app.
    static func closeSwitcher() {
        holdCommand(false)
    }

    /// Presses left cmd when `down`, or lets it go, as a modifier change.
    private static func holdCommand(_ down: Bool) {
        guard let command = CGEvent(keyboardEventSource: nil, virtualKey: Key.leftCommand.keyCode, keyDown: down)
        else { return }
        command.type = .flagsChanged
        command.flags = Modifier.flags(command.flags, holding: down ? [.cmd] : [])
        post(command)
    }

    /// Marks `event` as Malum's own and posts it where the tap sees it, first in line.
    private static func post(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: marker)
        event.post(tap: .cghidEventTap)
    }
}
