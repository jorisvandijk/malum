import Foundation
import MalumCore
import MalumPlatform

/// Where the CLI writes its output and messages.
let terminal = Terminal()
/// The app's log, in the system log.
let systemLog = Log(writer: SystemLog())
/// The real disk.
let files = LocalFileSystem()
/// The real file locks.
let locks = LocalFileLocks()
/// Where Malum's own files go.
let paths = Paths(home: FileManager.default.homeDirectoryForCurrentUser.path)
/// Malum's executable inside Malum.app, or nil when it runs from elsewhere, such as a build folder.
let executable = Bundle.main.executableURL.flatMap { AppBundle.executable(at: $0.resolvingSymlinksInPath().path) }

/// Shows a message in the terminal and writes it to the log, for what the app does.
@MainActor
func announce(_ message: Message) {
    terminal.report(message)
    systemLog.report(message)
}

/// Links `~/.local/bin/malum` on first start. Anything already there is left for `malum init`.
@MainActor
func linkOnFirstStart() {
    guard let executable else { return }
    do {
        guard try CommandLink(files: files, paths: paths).createIfMissing(to: executable) else { return }
        announce(Message(.info, "linked \(private: paths.commandLink) to \(private: executable)"))
    } catch {
        announce(Message(.warn, error.text))
    }
}

/// Runs what the command line asked for.
@MainActor
func runCommand(_ invocation: Invocation) {
    switch invocation {
    case .version:
        terminal.write(Project.version)
    case .help:
        terminal.write(Invocation.usage)
    case .initialize(let dots):
        /// What init did, one message per step.
        let messages = InitCommand(files: files, paths: paths)
            .run(dots: dots, workingDirectory: FileManager.default.currentDirectoryPath, executable: executable)
        messages.forEach(terminal.report)
        guard messages.allSatisfy({ $0.level != .error }) else { exit(EXIT_FAILURE) }
    case .reload:
        let instance = AppInstance(state: StateFolder(files: files, locks: locks, paths: paths), locks: locks)
        let message = ReloadCommand(instance: instance, signals: LocalSignals()).run()
        terminal.report(message)
        guard message.level != .error else { exit(EXIT_FAILURE) }
    case .incomplete(let command, let needs):
        terminal.report(Message(.error, "\(command) needs \(needs)"))
        terminal.write(Invocation.usage)
        exit(EXIT_FAILURE)
    case .unknown(let argument):
        terminal.report(Message(.error, "unknown argument: \(argument)"))
        terminal.write(Invocation.usage)
        exit(EXIT_FAILURE)
    }
}

/// What the command line asked for.
let invocation = Invocation(arguments: Array(CommandLine.arguments.dropFirst()))
switch invocation {
case .initialize:
    break  // init makes the link itself and reports it.
default:
    linkOnFirstStart()
}

switch LaunchMode(environment: ProcessInfo.processInfo.environment) {
case .app:
    runApp()
case .command:
    runCommand(invocation)
}
