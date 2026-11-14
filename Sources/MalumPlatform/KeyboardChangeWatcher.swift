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
    /// What to run for each change, as it comes in.
    private let onEach: @MainActor @Sendable (KeyboardChange) -> Void
    /// What to run once things settle.
    private let onChange: @MainActor @Sendable () -> Void
    /// The wake and login switch observers.
    private var observers: [any NSObjectProtocol] = []
    /// Where IOKit sends word of new keyboards.
    private var port: IONotificationPortRef?
    /// The keyboards plugged in since it was last read.
    private var added: io_iterator_t = 0

    /// Starts watching. `onEach` runs on the main actor for every change as it comes in, and
    /// `onChange` once a burst of changes has settled.
    public init(
        onEach: @escaping @MainActor @Sendable (KeyboardChange) -> Void,
        onChange: @escaping @MainActor @Sendable () -> Void
    ) {
        self.onEach = onEach
        self.onChange = onChange
        debouncer = Debouncer(delay: Self.settle)
        let center = NSWorkspace.shared.notificationCenter
        let changes: [Notification.Name: KeyboardChange] = [
            NSWorkspace.didWakeNotification: .woke, NSWorkspace.sessionDidBecomeActiveNotification: .sessionActive,
        ]
        observers = changes.map { name, change in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.changed(change) }
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
        changed(.keyboardAdded)
    }

    /// Calls back for `change` straight away, and again once things settle.
    private func changed(_ change: KeyboardChange) {
        onEach(change)
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
