/// The popup's list of what a run from the menu writes, newest line first, so the latest shows
/// while it runs. The search narrows it to the lines that hold the text. Tab doesn't reach it.
@MainActor
final class OutputList: PopupSource {
    /// The name of what wrote the lines, such as Run.
    private(set) var label = ""
    /// The lines, oldest first.
    private var lines: [String] = []

    /// The search field's grey text.
    var placeholder: String { OutputPopup.placeholder }

    /// Only Malum opens the list.
    var inTabOrder: Bool { false }

    /// Empties the list for a new run, named `label`.
    func start(_ label: String) {
        self.label = label
        lines = []
    }

    /// Adds `line` at the top.
    func add(_ line: String) {
        lines.append(line)
    }

    /// The lines holding `query`, ignoring case, newest first, or every line for an empty one.
    func rows(matching query: String) -> [PopupRow] {
        let words = query.lowercased()
        return lines.indices.reversed()
            .filter { words.allSatisfy(\.isWhitespace) || lines[$0].lowercased().contains(words) }
            .map { PopupRow(id: String($0), title: lines[$0]) }
    }

    /// Picking a line only closes the popup.
    func choose(_ row: PopupRow) {
        // A line is only there to read.
    }
}
