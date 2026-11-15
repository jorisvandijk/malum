import AppKit
import MalumCore

/// A web app's menus, so cmd+C, cmd+V, cmd+R, cmd+W and cmd+Q work in it.
@MainActor
enum WebAppMenu {
    /// One item: its title, what it does and its key with cmd.
    private struct Item {
        /// What the menu shows.
        let title: String
        /// What it sends to the first responder.
        let action: Selector
        /// Its key, with cmd.
        let key: String

        /// Creates the item.
        init(_ title: String, _ action: Selector, _ key: String) {
            self.title = title
            self.action = action
            self.key = key
        }
    }

    /// The menu bar of the web app called `name`.
    static func build(name: String) -> NSMenu {
        let bar = NSMenu()
        bar.addItem(
            submenu(
                name,
                [
                    Item(WebAppWords.hide(name), #selector(NSApplication.hide(_:)), "h"),
                    Item(WebAppWords.close, #selector(NSWindow.performClose(_:)), "w"),
                    Item(WebAppWords.quit(name), #selector(NSApplication.terminate(_:)), "q"),
                ]))
        bar.addItem(
            submenu(
                WebAppWords.edit,
                [
                    Item(WebAppWords.undo, Selector(("undo:")), "z"), Item(WebAppWords.redo, Selector(("redo:")), "Z"),
                    Item(WebAppWords.cut, #selector(NSText.cut(_:)), "x"),
                    Item(WebAppWords.copy, #selector(NSText.copy(_:)), "c"),
                    Item(WebAppWords.paste, #selector(NSText.paste(_:)), "v"),
                    Item(WebAppWords.selectAll, #selector(NSText.selectAll(_:)), "a"),
                ]))
        bar.addItem(
            submenu(
                WebAppWords.view,
                [
                    Item(WebAppWords.reload, #selector(WebAppWindow.reload(_:)), "r"),
                    Item(WebAppWords.back, #selector(WebAppWindow.goBack(_:)), "["),
                    Item(WebAppWords.forward, #selector(WebAppWindow.goForward(_:)), "]"),
                ]))
        return bar
    }

    /// A menu bar item titled `title` that opens a menu of `items`, each sent to the first responder.
    private static func submenu(_ title: String, _ items: [Item]) -> NSMenuItem {
        let menu = NSMenu(title: title)
        for item in items {
            menu.addItem(NSMenuItem(title: item.title, action: item.action, keyEquivalent: item.key))
        }
        let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        holder.submenu = menu
        return holder
    }
}
