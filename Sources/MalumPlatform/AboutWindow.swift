import AppKit
import MalumCore

/// The About window: Malum's logo beside its name and version, who makes it, and a link to its
/// website.
/// Malum becomes the active app while it shows, so its link gets the pointing hand, and esc or its
/// close button shuts it and hands the front back to the app before.
@MainActor
public final class AboutWindow: NSPanel {
    /// The room between the logo and the text.
    private static let logoGap = 32.0
    /// The room between the lines of text.
    private static let lineGap = 6.0
    /// The room of one empty line, between the version and the author.
    private static let blankLine = 18.0
    /// How big the logo is drawn, in points.
    private static let logoSize = 128.0
    /// The narrowest the text column gets, so the window is wider than it's tall.
    private static let textWidth = 260.0

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

    /// Makes Malum the active app and shows the window near the middle of the screen.
    public func present() {
        NSApplication.shared.activate()
        center()
        makeKeyAndOrderFront(nil)
    }

    /// Closes the window and hands the front back to the app that had it.
    override public func close() {
        super.close()
        NSApplication.shared.deactivate()
    }

    /// Opens the website in the default browser and closes the window.
    @objc private func openWebsite() {
        close()
        guard let url = URL(string: Project.website) else { return }
        NSWorkspace.shared.open(url)
    }

    /// The logo on the left, and the name, version, author and `link` on its right, with an empty
    /// line between the version and the author.
    private static func contents(link: LinkButton) -> NSStackView {
        let logo = NSImageView(image: NSApplication.shared.applicationIconImage)
        logo.imageScaling = .scaleProportionallyUpOrDown
        logo.widthAnchor.constraint(equalToConstant: logoSize).isActive = true
        logo.heightAnchor.constraint(equalToConstant: logoSize).isActive = true
        let row = NSStackView(views: [logo, text(link: link)])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = logoGap
        let margin = PanelLayout.margin
        row.edgeInsets = NSEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        return row
    }

    /// The name, version, author and `link`, one under the other.
    private static func text(link: LinkButton) -> NSStackView {
        let name = NSTextField(labelWithString: Project.name)
        name.font = .boldSystemFont(ofSize: NSFont.systemFontSize(for: .large))
        let version = NSTextField(labelWithString: AboutWords.version(Project.version))
        version.textColor = .secondaryLabelColor
        let author = NSTextField(labelWithString: Project.author)
        let column = NSStackView(views: [name, version, author, link])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = lineGap
        column.setCustomSpacing(lineGap + blankLine, after: version)
        column.widthAnchor.constraint(greaterThanOrEqualToConstant: textWidth).isActive = true
        return column
    }

    /// The website as a link that calls `openWebsite` on `target`.
    private static func link(target: AboutWindow) -> LinkButton {
        LinkButton(Project.website, target: target, action: #selector(openWebsite))
    }
}
