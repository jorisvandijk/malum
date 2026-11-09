import Foundation

/// The two files one screenshot is saved as: the plain shot and the one with drawings on it, named
/// `malum-ss-<date>_<time>.png` and `malum-ss-<date>_<time>-annotated.png`.
public struct ScreenshotFiles: Equatable, Sendable {
    /// What every screenshot's name starts with.
    private static let prefix = "\(Project.command)-ss-"
    /// What the annotated file adds to the plain one's name.
    private static let annotatedSuffix = "-annotated"
    /// The files' extension.
    private static let fileExtension = ".png"
    /// The date and time in a name, sortable and without colons.
    private static let stampFormat = "yyyy-MM-dd_HH-mm-ss"
    /// The locale that writes the stamp the same way whatever the Mac's language.
    private static let stampLocale = "en_US_POSIX"
    /// The first number added to a name that's taken.
    private static let firstExtraNumber = 2

    /// The plain shot's path.
    public let plain: String
    /// The annotated shot's path.
    public let annotated: String

    /// The files for a shot taken at `date`, in `timeZone`, in `folder`. When either name is taken
    /// according to `isTaken`, both get the next free `-2`, `-3`… so the pair stays together.
    public static func next(
        at date: Date, in folder: String, timeZone: TimeZone = .current, isTaken: (String) -> Bool
    ) -> Self {
        let base = folder + "/" + prefix + stamp(date, in: timeZone)
        var files = Self(base: base)
        var number = firstExtraNumber
        while isTaken(files.plain) || isTaken(files.annotated) {
            files = Self(base: base + "-\(number)")
            number += 1
        }
        return files
    }

    /// The files whose names start with `base`, a path without extension.
    private init(base: String) {
        plain = base + Self.fileExtension
        annotated = base + Self.annotatedSuffix + Self.fileExtension
    }

    /// `date` as it appears in a name, in `timeZone`.
    private static func stamp(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: stampLocale)
        formatter.timeZone = timeZone
        formatter.dateFormat = stampFormat
        return formatter.string(from: date)
    }
}
