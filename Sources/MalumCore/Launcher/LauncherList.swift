/// The launcher's list in the popup: every app, A to Z, or the best matches for the search with
/// the apps started most often first among equals.
@MainActor
final class LauncherList: PopupSource {
    /// Every app, sorted by name.
    var apps: [LaunchableApp] = []
    /// How often each app was started, by its key.
    var counts: [String: Int] = [:]
    /// What picking an app does.
    private let onChoose: @MainActor (LaunchableApp) -> Void

    /// Creates an empty list that hands a picked app to `onChoose`.
    init(onChoose: @escaping @MainActor (LaunchableApp) -> Void) {
        self.onChoose = onChoose
    }

    /// The apps matching `query` as rows.
    func rows(matching query: String) -> [PopupRow] {
        let matching = FuzzyMatch.rank(apps, query: query, name: \.name) { [counts] left, right in
            let (leftCount, rightCount) = (counts[left.key] ?? 0, counts[right.key] ?? 0)
            guard leftCount == rightCount else { return leftCount > rightCount }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
        let shown = query.allSatisfy(\.isWhitespace) ? apps : matching
        return shown.map { PopupRow(id: $0.path, title: $0.name, icon: .file($0.path)) }
    }

    /// Starts or raises the app picked.
    func choose(_ row: PopupRow) {
        guard let app = apps.first(where: { $0.path == row.id }) else { return }
        onChoose(app)
    }
}
