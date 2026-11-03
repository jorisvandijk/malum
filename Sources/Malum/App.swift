import AppKit
import MalumCore
import MalumPlatform

/// Runs Malum as the menu bar app, or quits straight away when another app already runs.
@MainActor
func runApp() -> Never {
    let instance = AppInstance(state: StateFolder(files: files, locks: locks, paths: paths), locks: locks)
    do {
        guard try instance.claim(processID: getpid()) else {
            terminal.report(Message(.info, "\(Project.name) is already running"))
            exit(EXIT_SUCCESS)
        }
    } catch {
        terminal.report(Message(.error, error.description))
        exit(EXIT_FAILURE)
    }
    terminal.report(Message(.info, "\(Project.name) \(Project.version) is running"))
    let menuBar = MenuBar()
    // TODO: the schema of each module, once there are any.
    let config = LiveConfig(reloader: ConfigReloader(files: files, paths: paths, schemas: [:]))
    config.reload(force: true)
    let hangup = HangupWatcher { config.reload(force: true) }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    withExtendedLifetime((menuBar, config, hangup)) { app.run() }
    exit(EXIT_SUCCESS)
}
