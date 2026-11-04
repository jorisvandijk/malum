/// The App Store part of system config: installs every listed app that isn't installed yet, through
/// `mas`.
@MainActor
public struct AppStoreApps {
    /// Runs `mas`.
    private let runner: any CommandRunner
    /// The disk, to find `mas`.
    private let files: any FileSystem
    /// The run's sudo, since mas installs as root.
    private let sudo: SudoSession

    /// Creates the part, which runs `mas` through `runner`, looks for it on `files` and gets root
    /// from `sudo`.
    public init(runner: any CommandRunner, files: any FileSystem, sudo: SudoSession) {
        self.runner = runner
        self.files = files
        self.sudo = sudo
    }

    /// Installs the apps in `apps` that aren't installed yet, reporting each step as it goes. Says
    /// whether everything listed is installed now.
    public func run(_ apps: [AppStoreApp], report: (Message) -> Void) async -> Bool {
        guard !apps.isEmpty else { return true }
        guard files.item(at: Mas.path) != nil else {
            report(
                Message(
                    .error,
                    """
                    couldn't install App Store apps: mas isn't installed at \(private: Mas.path), \
                    add mas = "formula" to [homebrew] in \(Paths.packagesTOMLName)
                    """))
            return false
        }
        let listed = await runner.run(Mas.installed)
        guard listed.succeeded else {
            report(Message(.error, "couldn't list the installed App Store apps: \(listed.reason)"))
            return false
        }
        let installed = Mas.ids(in: listed.output)
        let missing = apps.filter { !installed.contains($0.id) }
        guard !missing.isEmpty else {
            report(Message(.info, "every listed App Store app is installed"))
            return true
        }
        guard await sudo.authorize(for: "install App Store apps", report: report) else { return false }
        var succeeded = true
        for app in missing {
            succeeded = await install(app, report: report) && succeeded
        }
        return succeeded
    }

    /// Installs one app, and says whether it worked.
    private func install(_ app: AppStoreApp, report: (Message) -> Void) async -> Bool {
        report(Message(.info, "installing App Store app \(app.name) (\(app.id))"))
        let result = await runner.run(Mas.install(app.id))
        guard result.succeeded else {
            report(Message(.error, "couldn't install App Store app \(app.name): \(result.reason)"))
            return false
        }
        report(Message(.info, "installed App Store app \(app.name)"))
        return true
    }
}
