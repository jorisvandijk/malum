import AppKit
import MalumCore

// TODO: show each module's state, missing permissions and config problems.
/// Malum's icon in the menu bar.
@MainActor
public final class MenuBar {
    /// The icon and its menu.
    private let item: NSStatusItem

    /// Puts the icon in the menu bar, with a menu that quits Malum.
    public init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = Project.name
        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Quit \(Project.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }
}
