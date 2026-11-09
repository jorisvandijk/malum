/// The one popup the launcher and clipboard history share: which list it shows, what the search
/// matches, and what each key and click does. Tab moves to the next list, keeping the search.
@MainActor
public final class PopupCenter {
    /// How many rows the popup shows at once, and how far page up and page down move.
    public static let visibleRows = 7

    /// The window.
    private let popup: any Popup
    /// The lists, by the id of the module that gives each.
    private var sources: [String: any PopupSource] = [:]
    /// The ids of the lists, in the order Tab goes through them.
    private var order: [String] = []
    /// The id of the list shown, or last shown.
    private var current: String?
    /// The search text.
    private var query = ""
    /// The rows that match and the selection.
    private var list = PopupList<PopupRow>(pageSize: visibleRows, canDelete: false)

    /// Creates the center for `popup`, and takes the popup's events.
    public init(popup: any Popup) {
        self.popup = popup
        popup.onEvent = { [weak self] event in self?.handle(event) }
    }

    /// Adds `source` as the list of module `id`, or replaces the one it gave before.
    public func register(_ source: any PopupSource, as id: String) {
        if sources[id] == nil { order.append(id) }
        sources[id] = source
    }

    /// Takes away module `id`'s list, closing the popup when it shows it.
    public func unregister(_ id: String) {
        sources[id] = nil
        order.removeAll { $0 == id }
        guard current == id else { return }
        current = nil
        popup.close()
    }

    /// The key of module `id`'s list: opens the popup on it, moves to it when the popup shows
    /// another list, or closes the popup when it shows this one.
    public func toggle(_ id: String) {
        guard sources[id] != nil else { return }
        guard popup.isOpen else {
            current = id
            query = ""
            refilter()
            popup.open(content)
            return
        }
        guard current != id else {
            popup.close()
            return
        }
        current = id
        refilter()
        popup.show(content)
    }

    /// Searches module `id`'s list again, after its rows changed, when the popup shows it.
    public func refresh(_ id: String) {
        guard popup.isOpen, current == id else { return }
        refilter()
        popup.show(content)
    }

    /// Carries out what happened in the popup.
    private func handle(_ event: PopupEvent) {
        switch event {
        case .query(let text):
            query = text
            refilter()
            popup.show(content)
        case .command(let command):
            carryOut(list.handle(command))
        case .clicked(let index):
            list.select(index)
            carryOut(list.handle(.choose))
        case .deleteClicked(let index):
            list.select(index)
            carryOut(list.handle(.delete))
        case .clearAll:
            source?.clear()
            refilter()
            popup.show(content)
        case .closed:
            break
        }
    }

    /// Does what the list decided after a key or a click.
    private func carryOut(_ outcome: PopupOutcome<PopupRow>) {
        switch outcome {
        case .stay:
            popup.show(content)
        case .choose(let row):
            let chosen = source
            popup.close()
            chosen?.choose(row)
        case .close:
            popup.close()
        case .switchList:
            moveToNextList()
        case .delete(let row):
            source?.delete(row)
            popup.show(content)
        }
    }

    /// Shows the list after the current one, keeping the search.
    private func moveToNextList() {
        guard let current, let place = order.firstIndex(of: current), order.count > 1 else { return }
        self.current = order[(place + 1) % order.count]
        refilter()
        popup.show(content)
    }

    /// The list shown.
    private var source: (any PopupSource)? {
        current.flatMap { sources[$0] }
    }

    /// Asks the list shown for the rows matching the search, with the first one selected.
    private func refilter() {
        list = PopupList(pageSize: Self.visibleRows, canDelete: source?.canDelete ?? false)
        list.show(source?.rows(matching: query) ?? [])
    }

    /// What the popup shows now.
    private var content: PopupContent {
        PopupContent(
            placeholder: source?.placeholder ?? "", label: source?.label ?? "", rows: list.rows,
            selection: list.selection, canDelete: source?.canDelete ?? false)
    }
}
