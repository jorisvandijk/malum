/// `malum init`: records where dots is and links `~/.local/bin/malum` to Malum's executable.
public struct InitCommand: Sendable {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths

    /// Creates the command.
    public init(files: any FileSystem, paths: Paths) {
        self.files = files
        self.paths = paths
    }

    /// Runs both steps, even when the first fails, and returns what happened.
    ///
    /// `executable` is Malum's executable inside Malum.app, or nil when Malum runs from elsewhere.
    public func run(dots: String, workingDirectory: String, executable: String?) -> [Message] {
        [
            recordDots(files.canonicalPath(paths.resolve(dots, relativeTo: workingDirectory))),
            linkCommand(to: executable),
        ]
    }

    /// Saves where dots is.
    private func recordDots(_ dots: String) -> Message {
        guard files.item(at: dots) == .directory else {
            return .failed(SetupError.dotsNotFound(path: dots))
        }
        let pointer = DotsPointer(files: files, paths: paths)
        do {
            let previous = try pointer.read()
            guard previous != dots else { return .dotsAlreadyAt(dots) }
            try pointer.write(dots)
            guard let previous else {
                return .dotsSaved(dots, in: paths.configFile)
            }
            return .dotsMoved(from: previous, to: dots)
        } catch {
            return .failed(error)
        }
    }

    /// Points the command link at Malum.
    private func linkCommand(to executable: String?) -> Message {
        let link = paths.commandLink
        guard let executable else { return .warning(SetupError.notInApp(path: link)) }
        do {
            switch try CommandLink(files: files, paths: paths).point(to: executable) {
            case .created:
                return .linked(link, to: executable)
            case .unchanged:
                return .alreadyLinked(link, to: executable)
            case .moved(let previous):
                return .linked(link, to: executable, from: previous)
            }
        } catch {
            return .failed(error)
        }
    }
}
