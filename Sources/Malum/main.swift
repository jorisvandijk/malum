import Foundation
import MalumCore

/// Where the CLI writes its output and messages.
let terminal = Terminal()

switch Invocation(arguments: Array(CommandLine.arguments.dropFirst())) {
case .version:
    terminal.write(Project.version)
case .help:
    terminal.write(Invocation.usage)
case .unknown(let argument):
    terminal.report(Message(.error, "unknown argument: \(argument)"))
    terminal.write(Invocation.usage)
    exit(EXIT_FAILURE)
}
