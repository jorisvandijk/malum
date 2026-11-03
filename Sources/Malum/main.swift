import Foundation
import MalumCore

/// Where the CLI writes its output and messages.
let terminal = Terminal()
/// The real disk.
let files = LocalFileSystem()
/// Where Malum's own files go.
let paths = Paths(home: FileManager.default.homeDirectoryForCurrentUser.path)
/// Malum's executable inside Malum.app, or nil when it runs from elsewhere, such as a build folder.
let executable = Bundle.main.executableURL.flatMap { AppBundle.executable(at: $0.resolvingSymlinksInPath().path) }

/// Links `~/.local/bin/malum` on first start. Anything already there is left for `malum init`.
@MainActor
func linkOnFirstStart() {
    guard let executable else { return }
    do {
        guard try CommandLink(files: files, paths: paths).createIfMissing(to: executable) else { return }
        terminal.report(Message(.info, "linked \(paths.commandLink) to \(executable)"))
    } catch {
        terminal.report(Message(.warn, error.description))
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
case .incomplete(let command, let needs):
    terminal.report(Message(.error, "\(command) needs \(needs)"))
    terminal.write(Invocation.usage)
    exit(EXIT_FAILURE)
case .unknown(let argument):
    terminal.report(Message(.error, "unknown argument: \(argument)"))
    terminal.write(Invocation.usage)
    exit(EXIT_FAILURE)
}
