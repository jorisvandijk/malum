import AppKit
import MalumCore

/// Opens the web app's window when it starts and again when it's opened with no window, and quits
/// when the window is closed.
@MainActor
final class WebAppDelegate: NSObject, NSApplicationDelegate {
    /// The window, once it's open.
    private var window: WebAppWindow?

    /// The web app's name, from its bundle.
    private static var name: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? ""
    }

    /// The site, from its bundle, or nil when the bundle names none.
    private static var site: URL? {
        (Bundle.main.object(forInfoDictionaryKey: WebAppInfo.urlKey) as? String).flatMap(URL.init(string:))
    }

    /// Sets up the menus and opens the window. A bundle without a site quits at once.
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let site = Self.site else {
            NSApplication.shared.terminate(nil)
            return
        }
        NSApplication.shared.mainMenu = WebAppMenu.build(name: Self.name)
        let window = WebAppWindow(site: site, name: Self.name)
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate()
    }

    /// Quits once the window is closed, like a browser tab closing.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
