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
/// The GitHub token, in the login keychain.
let tokens = KeychainTokenStore()
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
        finish([ReloadCommand(instance: AppInstance(state: state, locks: locks), signals: LocalSignals()).run()])
    case .safe, .disable:
        finish(applyOverride(invocation))
    case .permissions:
        checkTerminal()
    case .run(let force):
        applySystemConfig(force: force)
    case .rollback:
        finishing { await selfUpdate(github: GitHubAPI(token: nil)).rollBack { announce($0) } }
    case .status:
        showStatus()
    case .token(let remove):
        keepToken(remove: remove)
    case .incomplete, .unknown:
        reject(invocation)
    }
}

/// Runs `malum run`, then updates Malum, installing an older release too when `force` is set,
/// reporting as it goes, and exits once it's done.
@MainActor
func applySystemConfig(force: Bool) -> Never {
    finishing {
        let github = gitHub()
        let command = RunCommand(
            files: files, paths: paths, runner: runner, github: github, state: state,
            canAsk: isatty(STDIN_FILENO) == 1, handlers: WorkspaceAppHandlers())
        let applied = await command.run { announce($0) }
        let updated = await selfUpdate(github: github).run(force: force) { announce($0) }
        return applied && updated
    }
}

/// GitHub, with the token from the keychain when one is stored. A token that can't be read is
/// reported, and GitHub is asked without it.
@MainActor
func gitHub() -> GitHubAPI {
    do {
        return GitHubAPI(token: try tokens.token())
    } catch {
        announce(.tokenUnreadable(error))
        return GitHubAPI(token: nil)
    }
}

/// The command behind `malum token`, which checks a new token without the stored one.
@MainActor
func tokenCommand() -> TokenCommand {
    TokenCommand(store: tokens, github: GitHubAPI(token: nil))
}

/// Runs `malum token`: asks for the token with typing hidden and keeps it, or removes it when
/// `remove` is set. Exits once it's done.
@MainActor
func keepToken(remove: Bool) -> Never {
    let command = tokenCommand()
    guard !remove else {
        finish([command.remove()])
        exit(EXIT_SUCCESS)
    }
    let entered = terminal.readSecret(prompt: TokenCommand.prompt)
    finishing {
        let message = await command.save(entered)
        terminal.report(message)
        return message.level != .error
    }
}

/// Updates the installed app from `github`, and rolls it back.
@MainActor
func selfUpdate(github: any GitHub) -> SelfUpdate {
    let certificate = SigningCertificate(
        runner: runner, files: files, paths: paths, temporaryDirectory: NSTemporaryDirectory())
    return SelfUpdate(
        github: github, runner: runner, files: files, paths: paths, state: state, certificate: certificate,
        executable: executable, current: Project.version, userID: getuid())
}

/// Runs `malum status`, which only reports to the terminal, and exits once it's done.
@MainActor
func showStatus() -> Never {
    terminal.report(tokenCommand().status())
    finishing {
        await StatusCommand(files: files, paths: paths, runner: runner, state: state).run { terminal.report($0) }
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
    case .version, .help, .initialize, .reload, .safe, .disable, .permissions, .run, .rollback, .status, .token:
        break  // These make sense; runCommand runs them.
    }
    terminal.write(Invocation.usage)
    exit(EXIT_FAILURE)
}

/// Runs `malum safe`, or `malum disable` when `invocation` is that, and gives back what it says.
@MainActor
func applyOverride(_ invocation: Invocation) -> [Message] {
    guard case .disable(let module) = invocation else { return overrideCommand().safe() }
    return overrideCommand().disable(module)
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
