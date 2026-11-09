import AppKit
import IOKit
import IOKit.hid
import MalumCore

/// Calls back when macOS may have dropped the key remaps or the event tap: the Mac woke, the user
/// switched back to this login, or a keyboard was plugged in or reconnected.
///
/// Lives as long as the app, so it never takes its observers or notifications down.
@MainActor
public final class KeyboardChangeWatcher {
    /// How long to wait for things to settle, since a wake can bring keyboards back one by one.
    private static let settle = Duration.seconds(1)

    /// Gathers a burst of changes into one call back.
    private let debouncer: Debouncer
    /// What to run once things settle.
    private let onChange: @MainActor @Sendable () -> Void
    /// The wake and login switch observers.
    private var observers: [any NSObjectProtocol] = []
    /// Where IOKit sends word of new keyboards.
    private var port: IONotificationPortRef?
    /// The keyboards plugged in since it was last read.
    private var added: io_iterator_t = 0

    /// Starts watching. `onChange` runs on the main actor once a burst of changes has settled.
    public init(onChange: @escaping @MainActor @Sendable () -> Void) {
        self.onChange = onChange
        debouncer = Debouncer(delay: Self.settle)
        let center = NSWorkspace.shared.notificationCenter
        observers = [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification].map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.changed() }
            }
        }
        watchKeyboards()
    }

    /// Asks IOKit to say when a keyboard appears. The keyboards there already are read and skipped,
    /// which also arms the notification.
    private func watchKeyboards() {
        guard let port = IONotificationPortCreate(kIOMainPortDefault), let matching = IOServiceMatching(kIOHIDDeviceKey)
        else { return }
        self.port = port
        IONotificationPortSetDispatchQueue(port, .main)
        let keyboards = matching as NSMutableDictionary
        keyboards[kIOHIDPrimaryUsagePageKey] = kHIDPage_GenericDesktop
        keyboards[kIOHIDPrimaryUsageKey] = kHIDUsage_GD_Keyboard
        let context = Unmanaged.passUnretained(self).toOpaque()
        let result = IOServiceAddMatchingNotification(
            port, kIOFirstMatchNotification, keyboards as CFDictionary, keyboardAdded, context, &added)
        guard result == KERN_SUCCESS else { return }
        _ = Self.drain(added)  // The keyboards plugged in before Malum started.
    }

    /// Reads the keyboards plugged in since the last time, and calls back when there was one.
    fileprivate func keyboardsAdded() {
        guard Self.drain(added) else { return }
        changed()
    }

    /// Calls back once things settle.
    private func changed() {
        debouncer.schedule { [onChange] in onChange() }
    }

    /// Lets go of every device `iterator` holds, which arms it for the next one, and says whether it
    /// held any.
    private static func drain(_ iterator: io_iterator_t) -> Bool {
        var found = false
        var device = IOIteratorNext(iterator)
        while device != 0 {
            IOObjectRelease(device)
            found = true
            device = IOIteratorNext(iterator)
        }
        return found
    }
}

/// What IOKit calls on the main queue when a keyboard appears, with the watcher as `context`.
private func keyboardAdded(context: UnsafeMutableRawPointer?, iterator _: io_iterator_t) {
    guard let context else { return }
    let watcher = Unmanaged<KeyboardChangeWatcher>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated { watcher.keyboardsAdded() }
}
