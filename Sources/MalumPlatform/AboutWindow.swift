import AppKit
import MalumCore

/// The About window: Malum's logo, name and version, who makes it, and a link to its website.
/// Like the inspector, it shows without making Malum the active app, and esc or its close button
/// shuts it.
@MainActor
public final class AboutWindow: NSPanel {
    /// The room round the contents and between its lines.
    private static let margin = 20.0
    /// The room between the lines of text.
    private static let lineGap = 4.0
    /// How big the logo is drawn, in points.
    private static let logoSize = 128.0

    /// Creates the window, hidden, with its contents laid out.
    public init() {
        super.init(
            contentRect: .zero, styleMask: [.titled, .closable, .nonactivatingPanel], backing: .buffered,
            defer: true)
        title = AboutWords.title
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        let stack = Self.contents(link: Self.link(target: self))
        contentView = stack
        setContentSize(stack.fittingSize)
    }

    /// Not used: the window is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Takes the keys, for esc.
    override public var canBecomeKey: Bool { true }

    /// Esc closes the window.
    override public func cancelOperation(_ sender: Any?) {
        close()
    }

    /// Shows the window near the middle of the screen.
    public func present() {
        center()
        makeKeyAndOrderFront(nil)
    }

    /// Opens the website in the default browser.
    @objc private func openWebsite() {
        guard let url = URL(string: Project.website) else { return }
        NSWorkspace.shared.open(url)
    }

    /// The logo above the name, version, author and `link`, centred.
    private static func contents(link: NSButton) -> NSStackView {
        let logo = NSImageView(image: NSApplication.shared.applicationIconImage)
        logo.imageScaling = .scaleProportionallyUpOrDown
        logo.widthAnchor.constraint(equalToConstant: logoSize).isActive = true
        logo.heightAnchor.constraint(equalToConstant: logoSize).isActive = true
        let name = NSTextField(labelWithString: Project.name)
        name.font = .boldSystemFont(ofSize: NSFont.systemFontSize(for: .large))
        let version = NSTextField(labelWithString: AboutWords.version(Project.version))
        version.textColor = .secondaryLabelColor
        let author = NSTextField(labelWithString: Project.author)
        let stack = NSStackView(views: [logo, name, version, author, link])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = lineGap
        stack.setCustomSpacing(margin, after: logo)
        stack.edgeInsets = NSEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        return stack
    }

    /// The website as a link that calls `openWebsite` on `target`.
    private static func link(target: AboutWindow) -> NSButton {
        let button = NSButton(title: Project.website, target: target, action: #selector(openWebsite))
        button.isBordered = false
        button.attributedTitle = NSAttributedString(
            string: Project.website,
            attributes: [.foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue])
        return button
    }
}
