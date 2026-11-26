/// Which of an app's stacked windows is shown: the windows it was shown, most recent first, so when
/// the shown one closes, the one shown before it comes up. `Item` names a window.
struct WindowStack<Item: Hashable> {
    /// The windows shown so far, most recent first.
    private var recent: [Item] = []

    /// Makes `item` the shown window.
    mutating func show(_ item: Item) {
        recent.removeAll { $0 == item }
        recent.insert(item, at: 0)
    }

    /// Forgets the windows that aren't in `items` any more, such as closed ones.
    mutating func keep(_ items: [Item]) {
        recent.removeAll { !items.contains($0) }
    }

    /// Which of `items` is shown: the most recently shown one, or the first when none was shown yet.
    func shown(among items: [Item]) -> Item? {
        recent.first(where: items.contains) ?? items.first
    }

    /// The window `offset` places from the shown one in `items`, wrapping around at either end, or
    /// nil when there are none.
    func step(_ offset: Int, among items: [Item]) -> Item? {
        guard let shown = shown(among: items), let index = items.firstIndex(of: shown) else { return nil }
        let count = items.count
        return items[((index + offset) % count + count) % count]
    }
}
