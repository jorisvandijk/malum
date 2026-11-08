import AppKit
import MalumCore
import UniformTypeIdentifiers

/// Which app opens which links and files, through `NSWorkspace`.
@MainActor
public struct WorkspaceAppHandlers {
    /// Creates the handlers.
    public init() {}

    /// The link that stands for every link with `scheme`.
    private static func link(_ scheme: String) -> URL? {
        URL(string: "\(scheme):")
    }
}

// MARK: - AppHandlers

extension WorkspaceAppHandlers: AppHandlers {
    /// Whether macOS knows `target`: every scheme, and the file types some app or macOS declares.
    public func isKnown(_ target: OpenTarget) -> Bool {
        switch target {
        case .scheme: true
        case .contentType(let type): UTType(type) != nil
        }
    }

    /// The bundle ID of the app that opens `target` now, or nil when none does.
    public func handler(for target: OpenTarget) -> String? {
        let app: URL? =
            switch target {
            case .scheme(let scheme): Self.link(scheme).flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
            case .contentType(let type): UTType(type).flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
            }
        return app.flatMap { Bundle(url: $0)?.bundleIdentifier }
    }

    /// Where the app with the bundle ID `bundleID` is, or nil when it isn't installed.
    public func app(_ bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    /// Makes the app at `app` the one that opens `target`. A file type macOS doesn't know is left alone.
    public func setHandler(for target: OpenTarget, to app: URL) async throws {
        // NSWorkspace isn't Sendable, so it's called here on the main actor and only its answer comes back.
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, any Error>) in
            let finish: @Sendable ((any Error)?) -> Void = { error in
                guard let error else { return done.resume() }
                done.resume(throwing: error)
            }
            switch target {
            case .scheme(let scheme):
                NSWorkspace.shared.setDefaultApplication(at: app, toOpenURLsWithScheme: scheme) { finish($0) }
            case .contentType(let type):
                guard let type = UTType(type) else { return done.resume() }
                NSWorkspace.shared.setDefaultApplication(at: app, toOpen: type) { finish($0) }
            }
        }
    }
}
