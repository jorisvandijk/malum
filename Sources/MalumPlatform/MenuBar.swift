import AppKit
import MalumCore

/// Malum's icon in the menu bar, and its menu.
@MainActor
public final class MenuBar: NSObject {
    /// The Malum logo in the app bundle's resources, shown while everything is fine.
    private static let logoName = "MenuBarIcon"
    /// The logo's file type.
    private static let logoType = "pdf"
    /// The SF Symbol shown instead of the logo when Malum runs outside its app bundle.
    private static let calmSymbol = "leaf"
    /// The SF Symbol shown while something needs attention.
    private static let alertSymbol = "exclamationmark.triangle"

    /// The icon and its menu.
    private let item: NSStatusItem
    /// What to do with the items the app handles: reloading, changing the overrides and quitting.
    private let onPick: @MainActor (MenuFix) -> Void
    /// What each item that can be picked does, by the item's tag.
    private var fixes: [MenuFix] = []
    /// The logo, drawn in the menu bar's own colours, or nil outside the app bundle.
    private let logo: NSImage?

    /// Puts the icon in the menu bar. `onPick` runs when the user picks an item the app handles:
    /// reload, leave safe mode, enable a module, or quit.
    public init(onPick: @escaping @MainActor (MenuFix) -> Void) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        logo = Self.loadLogo()
        self.onPick = onPick
        super.init()
    }

    /// Shows `menu`: the icon changes when something needs attention, and the menu is rebuilt.
    public func show(_ menu: StatusMenu) {
        let label = menu.label
        if menu.needsAttention {
            item.button?.image = NSImage(systemSymbolName: Self.alertSymbol, accessibilityDescription: label)
        } else {
            item.button?.image = calmImage(label)
        }
        item.button?.toolTip = label
        fixes = []
        let built = NSMenu()
        built.autoenablesItems = false
        for line in menu.items {
            built.addItem(menuItem(for: line))
        }
        item.menu = built
    }

    /// The logo with `label` read out for it, or the leaf when there's no logo.
    private func calmImage(_ label: String) -> NSImage? {
        guard let logo else {
            return NSImage(systemSymbolName: Self.calmSymbol, accessibilityDescription: label)
        }
        logo.accessibilityDescription = label
        return logo
    }

    /// Reads the logo from the app bundle as a template image, or nil when Malum runs outside it.
    private static func loadLogo() -> NSImage? {
        guard let url = Bundle.main.url(forResource: logoName, withExtension: logoType),
            let image = NSImage(contentsOf: url)
        else { return nil }
        image.isTemplate = true
        return image
    }

    /// The AppKit item for one line.
    private func menuItem(for line: MenuItem) -> NSMenuItem {
        switch line {
        case .separator:
            return .separator()
        case .text(let title):
            let text = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            text.isEnabled = false
            return text
        case .action(let title, let fix):
            let key = fix == .quit ? "q" : ""
            let action = NSMenuItem(title: title, action: #selector(picked(_:)), keyEquivalent: key)
            action.target = self
            action.tag = fixes.count
            fixes.append(fix)
            return action
        }
    }

    /// Does what the picked item says.
    @objc private func picked(_ sender: NSMenuItem) {
        guard fixes.indices.contains(sender.tag) else { return }
        let fix = fixes[sender.tag]
        switch fix {
        case .openFile(let path):
            Self.open(file: path)
        case .showFolder(let path):
            NSWorkspace.shared.open(URL(fileURLWithPath: path, isDirectory: true))
        case .openSettings(let permission):
            PermissionProbe.request(permission)
            PrivacySettings.open(permission)
        case .reload, .leaveSafeMode, .enable, .quit:
            onPick(fix)
        }
    }

    /// Opens `path` in its default app, or shows it in Finder when no app takes it.
    private static func open(file path: String) {
        let url = URL(fileURLWithPath: path)
        guard !NSWorkspace.shared.open(url) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
