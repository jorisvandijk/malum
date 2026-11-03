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
        [recordDots(paths.resolve(dots, relativeTo: workingDirectory)), linkCommand(to: executable)]
    }

    /// Saves where dots is.
    private func recordDots(_ dots: String) -> Message {
        guard files.item(at: dots) == .directory else {
            return Message(.error, SetupError.dotsNotFound(path: dots).description)
        }
        let pointer = DotsPointer(files: files, paths: paths)
        do {
            let previous = try pointer.read()
            guard previous != dots else { return Message(.info, "dots is already at \(dots)") }
            try pointer.write(dots)
            guard let previous else { return Message(.info, "dots is at \(dots), saved in \(paths.configFile)") }
            return Message(.info, "dots moved from \(previous) to \(dots)")
        } catch {
            return Message(.error, error.description)
        }
    }

    /// Points the command link at Malum.
    private func linkCommand(to executable: String?) -> Message {
        let link = paths.commandLink
        guard let executable else { return Message(.warn, SetupError.notInApp(path: link).description) }
        do {
            switch try CommandLink(files: files, paths: paths).point(to: executable) {
            case .created:
                return Message(.info, "linked \(link) to \(executable)")
            case .unchanged:
                return Message(.info, "\(link) already points to \(executable)")
            case .moved(let previous):
                return Message(.info, "linked \(link) to \(executable), it pointed to \(previous)")
            }
        } catch {
            return Message(.error, error.description)
        }
    }
}
