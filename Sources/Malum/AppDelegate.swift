import AppKit

/// Stops the modules before Malum quits, however it's asked to: the menu, `SIGTERM` or logging out.
/// Stopping undoes what they changed system-wide, such as the hyper key's remap.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Starts and stops the modules.
    private let config: LiveConfig

    /// Creates the delegate for the modules `config` runs.
    init(config: LiveConfig) {
        self.config = config
    }

    /// Lets Malum quit once every module has stopped.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task { [config] in
            await config.stopModules()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
