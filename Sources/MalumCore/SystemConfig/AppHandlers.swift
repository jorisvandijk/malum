import Foundation

/// Which app opens which links and files on this Mac, as macOS keeps it.
@MainActor
public protocol AppHandlers {
    /// Whether macOS knows `target`. A file type no app on this Mac declares is unknown, and nothing
    /// can be made to open it yet.
    func isKnown(_ target: OpenTarget) -> Bool

    /// The bundle ID of the app that opens `target` now, or nil when none does.
    func handler(for target: OpenTarget) -> String?

    /// Where the app with the bundle ID `bundleID` is, or nil when it isn't installed.
    func app(_ bundleID: String) -> URL?

    /// Makes the app at `app` the one that opens `target`. macOS first asks the user to confirm it in
    /// a dialog of its own.
    func setHandler(for target: OpenTarget, to app: URL) async throws
}
