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
/// Malum's state folder, shared by the app and the command.
let state = StateFolder(files: files, locks: locks, paths: paths)
/// Runs the outside tools.
let runner = ProcessRunner(home: paths.home)
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
        announce(.linked(paths.commandLink, to: executable))
    } catch {
        announce(.warning(error))
    }
}

/// Runs what the command line asked for.
@MainActor
func runCommand(_ invocation: Invocation) {
    switch invocation {
    case .version, .help:
        terminal.write(invocation == .version ? Project.version : Invocation.usage)
    case .initialize(let dots):
        finish(
            InitCommand(files: files, paths: paths)
                .run(dots: dots, workingDirectory: FileManager.default.currentDirectoryPath, executable: executable))
    case .reload:
        let instance = AppInstance(state: state, locks: locks)
        let message = ReloadCommand(instance: instance, signals: LocalSignals()).run()
        terminal.report(message)
        guard message.level != .error else { exit(EXIT_FAILURE) }
    case .safe:
        finish(overrideCommand().safe())
    case .disable(let module):
        finish(overrideCommand().disable(module))
    case .permissions:
        checkTerminal()
    case .run:
        applySystemConfig()
    case .status:
        showStatus()
    case .incomplete, .unknown:
        reject(invocation)
    }
}

/// Runs `malum run`, reporting as it goes, and exits once it's done.
@MainActor
func applySystemConfig() -> Never {
    finishing {
        let command = RunCommand(
            files: files, paths: paths, runner: runner, github: GitHubAPI(), locks: locks,
            canAsk: isatty(STDIN_FILENO) == 1, handlers: WorkspaceAppHandlers())
        return await command.run { announce($0) }
    }
}

/// Runs `malum status`, which only reports to the terminal, and exits once it's done.
@MainActor
func showStatus() -> Never {
    finishing {
        await StatusCommand(files: files, paths: paths, runner: runner, locks: locks).run { terminal.report($0) }
    }
}

/// Runs `work`, then exits with an error when it says it didn't succeed.
@MainActor
func finishing(_ work: @escaping @MainActor () async -> Bool) -> Never {
    Task {
        let succeeded = await work()
        exit(succeeded ? EXIT_SUCCESS : EXIT_FAILURE)
    }
    dispatchMain()
}

/// Says what's wrong with the arguments, shows how to use the command, and exits with an error.
@MainActor
func reject(_ invocation: Invocation) -> Never {
    switch invocation {
    case .incomplete(let command, let needs):
        terminal.report(.incomplete(command, needs: needs))
    case .unknown(let argument):
        terminal.report(.unknownArgument(argument))
    case .version, .help, .initialize, .reload, .safe, .disable, .permissions, .run, .status:
        break  // These make sense; runCommand runs them.
    }
    terminal.write(Invocation.usage)
    exit(EXIT_FAILURE)
}

/// The command behind `malum safe` and `malum disable`.
@MainActor
func overrideCommand() -> OverrideCommand {
    OverrideCommand(
        store: OverrideStore(state: state), instance: AppInstance(state: state, locks: locks), signals: LocalSignals())
}

/// Says whether the terminal has Full Disk Access, and opens its page in System Settings when it doesn't.
@MainActor
func checkTerminal() {
    let name = TerminalApp.name(
        environment: ProcessInfo.processInfo.environment, isTerminal: isatty(STDIN_FILENO) == 1)
    let access = TerminalAccess(terminal: name, check: PermissionProbe(home: paths.home))
    terminal.report(access.report())
    guard access.isMissing else { return }
    guard PrivacySettings.open(.fullDiskAccess) else {
        terminal.report(.settingsUnopenable(at: .fullDiskAccess))
        return
    }
    terminal.report(.openedSettings(at: .fullDiskAccess))
}

/// Shows `messages`, and exits with an error when one of them is an error.
@MainActor
func finish(_ messages: [Message]) {
    messages.forEach(terminal.report)
    guard messages.allSatisfy({ $0.level != .error }) else { exit(EXIT_FAILURE) }
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
