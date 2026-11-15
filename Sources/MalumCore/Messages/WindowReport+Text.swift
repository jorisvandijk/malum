import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The window inspector's report as words.
extension WindowReport {
    /// What a field shows when the window doesn't say.
    private static let none = "none"

    /// The report, one line per field, in the order the inspector shows them.
    var lines: [InspectorLine] {
        [
            InspectorLine(label: "app", value: app ?? Self.none),
            InspectorLine(label: "bundle id", value: bundleID ?? Self.none),
            InspectorLine(label: "title", value: facts.title ?? Self.none),
            InspectorLine(label: "role", value: role),
            InspectorLine(label: "frame", value: frame.map(Self.words) ?? Self.none),
            InspectorLine(label: "workspace", value: workspace),
            InspectorLine(label: "window manager", value: handlingWords),
        ]
    }

    /// The report as the Copy button puts it on the clipboard, one `label: value` line per field.
    var text: String {
        lines.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
    }

    /// The role and subrole, such as `AXWindow / AXStandardWindow`.
    private var role: String {
        [facts.role, facts.subrole].compactMap(\.self).joined(separator: " / ").nonEmpty ?? Self.none
    }

    /// The workspace keys, such as `hyper+f`.
    private var workspace: String {
        keys.map(\.description).joined(separator: ", ").nonEmpty ?? Self.none
    }

    /// What the window manager does with the window.
    private var handlingWords: String {
        switch handling {
        case .kind(.managed):
            "managed"
        case .kind(.float(let reason)):
            "floats: \(reason)"
        case .kind(.notReady):
            "doesn't say what it is yet"
        case .appNotTracked:
            "left alone: its app only runs in the menu bar or in the background"
        }
    }

    /// `frame` as its size and top left corner, such as `1512x957 at 0,25`.
    private static func words(_ frame: CGRect) -> String {
        "\(Int(frame.width))x\(Int(frame.height)) at \(Int(frame.minX)),\(Int(frame.minY))"
    }
}

/// The empty string as nil.
extension String {
    /// Nil when empty, so `??` can give a stand-in.
    fileprivate var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

/// The window inspector's log lines.
extension Message {
    /// The click wasn't on a window Accessibility reaches.
    static let noWindowThere = Message(.info, "inspect window: no window there")

    /// The Copy button couldn't put the report on the clipboard.
    static let couldntCopyReport = couldnt("copy the window's report", "the clipboard didn't take it")
}
