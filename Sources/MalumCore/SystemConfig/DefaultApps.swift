import Foundation

/// Makes the apps `[default_apps]` in `macos.toml` names, by bundle ID, open what they're for:
/// `browser` web links and pages, `video` video files. A file type no app on this Mac declares is
/// skipped until one does. A key taken out of the file leaves the default app as it is. macOS asks
/// the user to confirm each change.
@MainActor
struct DefaultApps {
    /// The table of default apps.
    static let table = "default_apps"

    /// The bundle ID of each app `macos.toml` names, by its key in `[default_apps]`.
    typealias Wanted = [String: String]

    /// What the app of each key in `[default_apps]` opens.
    private static let targets: [String: [OpenTarget]] = [
        "browser": ["http", "https"].map(OpenTarget.scheme)
            + ["public.html", "public.xhtml"].map(OpenTarget.contentType),
        "video": [
            "public.mpeg-4", "com.apple.quicktime-movie", "public.avi", "org.matroska.mkv", "public.3gpp",
            "public.mpeg", "com.microsoft.windows-media-wmv",
        ].map(OpenTarget.contentType),
    ]

    /// Says which app opens what, and changes it.
    private let handlers: any AppHandlers

    /// Creates the part, which sets the default apps through `handlers`.
    init(handlers: any AppHandlers) {
        self.handlers = handlers
    }

    /// The apps in `[default_apps]`, adding a problem to `reader` for each one that's wrong.
    static func read(_ reader: inout TableReader) -> Wanted {
        let apps = reader.table(reader.document, table, at: [])
        reader.unknownKeys(apps, at: [table], known: targets.keys.sorted())
        var wanted: Wanted = [:]
        for (key, value) in apps.sorted(by: { $0.key < $1.key }) where targets[key] != nil {
            let path = [table, key]
            guard case .string(let bundleID) = value else {
                reader.expect(path, SettingKind.string)
                continue
            }
            guard !bundleID.isEmpty, !bundleID.contains(where: \.isWhitespace) else {
                reader.add(.error, at: path, .notBundleID(TableReader.dotted(path)))
                continue
            }
            wanted[key] = bundleID
        }
        return wanted
    }

    /// Makes each app in `wanted` open what its key is for, where it doesn't yet. Says whether
    /// everything worked.
    func set(_ wanted: Wanted, report: (Message) -> Void) async -> Bool {
        var succeeded = true
        for (key, bundleID) in wanted.sorted(by: { $0.key < $1.key }) {
            guard let app = handlers.app(bundleID) else {
                report(.defaultAppMissing(TableReader.dotted([Self.table, key]), bundleID: bundleID))
                succeeded = false
                continue
            }
            let targets = (Self.targets[key] ?? []).filter(handlers.isKnown)
            succeeded = await set(bundleID, at: app, for: targets, report) && succeeded
        }
        return succeeded
    }

    /// Makes the app `bundleID` at `app` open each of `targets` that another app opens now. Stops
    /// at the first that fails, so an app turned down in macOS's dialog isn't asked for again.
    /// Says whether it worked.
    private func set(
        _ bundleID: String, at app: URL, for targets: [OpenTarget], _ report: (Message) -> Void
    ) async -> Bool {
        for target in targets where handlers.handler(for: target)?.lowercased() != bundleID.lowercased() {
            report(.confirmDefaultApp(bundleID, for: target))
            do {
                try await handlers.setHandler(for: target, to: app)
            } catch {
                report(.defaultAppNotSet(bundleID, for: target, reason: MessageText(error: error)))
                return false
            }
            report(.defaultAppSet(bundleID, for: target))
        }
        return true
    }
}
