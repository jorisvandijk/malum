import Foundation

@testable import MalumCore

/// Keeps which app opens what in memory instead of asking macOS.
@MainActor
final class FakeAppHandlers: AppHandlers {
    /// The bundle ID of each installed app.
    let installed: Set<String>
    /// The file types macOS doesn't know.
    let unknown: Set<String>
    /// The targets that can't be set, such as a browser turned down in macOS's dialog.
    let refused: [OpenTarget]
    /// The bundle ID of the app that opens each target now.
    private(set) var handlers: [OpenTarget: String]
    /// Every target set, in order.
    private(set) var set: [OpenTarget] = []

    init(
        installed: Set<String> = [], handlers: [OpenTarget: String] = [:], unknown: Set<String> = [],
        refused: [OpenTarget] = []
    ) {
        self.installed = installed
        self.handlers = handlers
        self.unknown = unknown
        self.refused = refused
    }

    func isKnown(_ target: OpenTarget) -> Bool {
        guard case .contentType(let type) = target else { return true }
        return !unknown.contains(type)
    }

    func handler(for target: OpenTarget) -> String? {
        handlers[target]
    }

    func app(_ bundleID: String) -> URL? {
        installed.contains(bundleID) ? URL(fileURLWithPath: "/Applications/\(bundleID).app") : nil
    }

    func setHandler(for target: OpenTarget, to app: URL) async throws {
        guard !refused.contains(target) else { throw FakeRefusal() }
        set.append(target)
        handlers[target] = app.deletingPathExtension().lastPathComponent
    }
}

/// What the fake throws for a refused target.
struct FakeRefusal: Error, CustomStringConvertible {
    var description: String { "the user kept the current one" }
}
