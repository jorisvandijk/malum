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
    let hangup = HangupWatcher {
        // TODO: reload the config and the modules once there are any.
        terminal.report(Message(.info, "reloading"))
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    withExtendedLifetime((menuBar, hangup)) { app.run() }
    exit(EXIT_SUCCESS)
}
