import Foundation

// MARK: - Words

extension ClipboardList {
    /// A minute, an hour and a day, in seconds, for an entry's age.
    private static let minute = 60
    /// An hour, in seconds.
    private static let hour = 3_600
    /// A day, in seconds.
    private static let day = 86_400

    /// The list's name in the popup.
    var label: String { "History" }
    /// The search field's grey text.
    var placeholder: String { "Search clipboard history" }

    /// What a row shows: a text's first line, the files' names, or that it's an image.
    static func title(of entry: ClipEntry) -> String {
        switch entry.kind {
        case .text:
            let lines = (entry.text ?? "").split(whereSeparator: \.isNewline)
            let first = lines.first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
            return lines.count > 1 ? "\(first) …" : first
        case .image:
            return "Image"
        case .files:
            return (entry.paths ?? []).map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
        }
    }

    /// What the search matches: the text, the files' names, or "image".
    static func searchText(_ entry: ClipEntry) -> String {
        switch entry.kind {
        case .text:
            entry.text ?? ""
        case .image:
            "image"
        case .files:
            title(of: entry)
        }
    }

    /// How long ago `date` was, short: now, 5m, 3h, 2d.
    static func age(since date: Date, now: Date) -> String {
        let seconds = max(Int(now.timeIntervalSince(date)), 0)
        switch seconds {
        case ..<minute:
            return "now"
        case ..<hour:
            return "\(seconds / minute)m"
        case ..<day:
            return "\(seconds / hour)h"
        default:
            return "\(seconds / day)d"
        }
    }
}
