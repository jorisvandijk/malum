/// The apps Malum opens when it starts, `[startup] apps` in `macos.toml`, by bundle ID: apps that
/// don't start at login by themselves. Malum stays out of Login Items, since its login agent starts
/// it. An app that already runs is left alone.
@MainActor
public struct StartupApps {
    /// The table of startup apps.
    static let table = "startup"
    /// The key in `[startup]` that lists them.
    private static let appsKey = "apps"

    /// The disk, where dots is.
    private let files: any FileSystem
    /// Where the dots pointer is.
    private let paths: Paths
    /// Opens the apps.
    private let apps: any AppControl

    /// Creates the opener, which reads `macos.toml` on `files` and opens the apps through `apps`.
    public init(files: any FileSystem, paths: Paths, apps: any AppControl) {
        self.files = files
        self.paths = paths
        self.apps = apps
    }

    /// The bundle IDs in `[startup] apps`, adding a problem to `reader` when it's wrong.
    static func read(_ reader: inout TableReader) -> [String] {
        reader.onlyList(appsKey, of: table, check: AppBundle.isBundleID, problem: MessageText.notBundleID)
    }

    /// Opens each listed app that isn't running. Does nothing when there's no dots or `macos.toml`.
    public func open(report: (Message) -> Void) async {
        let bundleIDs: [String]
        do {
            guard let dots = try DotsPointer(files: files, paths: paths).read() else { return }
            guard let text = try files.text(ifFileAt: paths.macOSTOML(in: dots)) else { return }
            var reader = try TableReader(text, file: Paths.macOSTOMLName)
            bundleIDs = Self.read(&reader)
            reader.problemsByLine.map(\.message).forEach(report)
        } catch {
            report(.failed(.openStartupApps, error))
            return
        }
        for bundleID in bundleIDs where apps.running(bundleID) == nil {
            do {
                try await apps.open(bundleID)
                report(.openedAtStart(bundleID))
            } catch {
                report(.warning(error))
            }
        }
    }
}
