import AppKit

// A web app: the site its bundle names, in one window of its own, with its own icon, its own place
// in cmd+tab and its own cookies, so it stays logged in.

/// The web app.
let app = NSApplication.shared
/// Opens the window and quits when it closes.
let delegate = WebAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
withExtendedLifetime(delegate) { app.run() }
