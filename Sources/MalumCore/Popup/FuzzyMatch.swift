import Foundation

/// The popup's search: every letter of the query has to appear in a name, in order. Case, accents
/// and spaces in the query don't count. Matches at the start of the name or of a word score higher.
public enum FuzzyMatch {
    /// Points for each letter that matches.
    private static let letterPoints = 16
    /// Extra points for a match on the name's first letter.
    private static let firstLetterPoints = 24
    /// Extra points for a match on the first letter of a word.
    private static let wordStartPoints = 12
    /// Extra points for a letter straight after the one before it.
    private static let runPoints = 12
    /// Extra points when the whole query is the start of the name.
    private static let prefixPoints = 40
    /// The most a late first match can cost, one point per letter before it.
    private static let maxStartPenalty = 10
    /// How far back a letter looks for the one before it across a gap of at least one letter.
    private static let gapDistance = 2

    /// How well `query` matches `name`, higher is better, or nil when it doesn't. An empty query
    /// matches everything with 0.
    public static func score(_ query: String, in name: String) -> Int? {
        let wanted = Array(fold(query).filter { !$0.isWhitespace })
        guard let first = wanted.first else { return 0 }
        let original = Array(name)
        let folded = original.map { fold(String($0)).first ?? $0 }
        guard wanted.count <= folded.count else { return nil }
        let bonus = original.indices.map { letterPoints + startBonus(original, at: $0) }
        var row = folded.indices.map { index in
            folded[index] == first ? bonus[index] - min(index, maxStartPenalty) : nil
        }
        for letter in wanted.dropFirst() {
            row = nextRow(after: row, letter: letter, folded: folded, bonus: bonus)
        }
        guard let best = row.compactMap({ $0 }).max() else { return nil }
        return folded.starts(with: wanted) ? best + prefixPoints : best
    }

    /// The items whose name matches `query`, best first; `ties` orders equally good ones.
    public static func rank<Item>(
        _ items: [Item], query: String, name: (Item) -> String, ties: (Item, Item) -> Bool
    ) -> [Item] {
        let scored = items.compactMap { item in score(query, in: name(item)).map { (item, $0) } }
        return scored.sorted { left, right in
            guard left.1 == right.1 else { return left.1 > right.1 }
            return ties(left.0, right.0)
        }.map(\.0)
    }

    /// The best score of the query so far with its next `letter` at each place in the name: right
    /// after the letter before earns run points, a gap costs a point for each letter skipped.
    private static func nextRow(
        after previous: [Int?], letter: Character, folded: [Character], bonus: [Int]
    ) -> [Int?] {
        var row = [Int?](repeating: nil, count: folded.count)
        // The best previous score plus its place, among places a gap away or more.
        var bestBeforeGap: Int?
        for index in folded.indices {
            if index >= gapDistance, let earlier = previous[index - gapDistance] {
                bestBeforeGap = max(bestBeforeGap ?? Int.min, earlier + index - gapDistance)
            }
            guard folded[index] == letter else { continue }
            let adjacent = index > 0 ? previous[index - 1].map { $0 + runPoints } : nil
            let afterGap = bestBeforeGap.map { $0 - (index - 1) }
            row[index] = [adjacent, afterGap].compactMap { $0 }.max().map { $0 + bonus[index] }
        }
        return row
    }

    /// The extra points for a match at `index`: the first letter, or the start of a word.
    private static func startBonus(_ name: [Character], at index: Int) -> Int {
        guard index > 0 else { return firstLetterPoints }
        return isWordStart(name[index], after: name[index - 1]) ? wordStartPoints : 0
    }

    /// Whether `letter` starts a word: after a space or punctuation, or a capital after a small
    /// letter ("Settings" in "SystemSettings", not "Code" in "VSCodium").
    private static func isWordStart(_ letter: Character, after before: Character) -> Bool {
        guard before.isLetter || before.isNumber else { return letter.isLetter || letter.isNumber }
        return letter.isUppercase && before.isLowercase
    }

    /// `text` with case, accents and width folded away.
    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}
