import Foundation

/// Compares a value Malum wants to set with what a domain holds now, so a preference that already
/// holds it isn't written again.
enum PlistMatch {
    /// How closely the value has to match.
    enum Rule: Sendable {
        /// The value is exactly what was asked for.
        case exact
        /// Every table in the value holds at least what was asked for. macOS adds its own keys to
        /// some settings it keeps as tables, such as the Dock's apps, and those stay.
        case containing
    }

    /// Whether `document`, a property list document, is held by `current` under `rule`.
    static func matches(_ document: String, _ current: Any?, rule: Rule) -> Bool {
        let data = Data(document.utf8)
        guard let current, let wanted = try? PropertyListSerialization.propertyList(from: data, format: nil)  // Ours.
        else { return false }
        switch rule {
        case .exact:
            return NSArray(object: wanted).isEqual(to: [current])
        case .containing:
            return contains(current, wanted)
        }
    }

    /// Whether `current` holds `wanted`: the same value, or a table with at least its keys, each
    /// holding what `wanted` has, and lists of the same length matched item by item.
    private static func contains(_ current: Any, _ wanted: Any) -> Bool {
        if let wantedTable = wanted as? [String: Any] {
            guard let currentTable = current as? [String: Any] else { return false }
            return wantedTable.allSatisfy { key, value in currentTable[key].map { contains($0, value) } ?? false }
        }
        if let wantedList = wanted as? [Any] {
            guard let currentList = current as? [Any], currentList.count == wantedList.count else { return false }
            return zip(currentList, wantedList).allSatisfy { contains($0, $1) }
        }
        return NSArray(object: wanted).isEqual(to: [current])
    }
}
