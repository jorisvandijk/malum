/// The link at `~/.local/bin/malum` that makes Malum's executable a command in the terminal.
public struct CommandLink: Sendable {
    /// The disk.
    private let files: any FileSystem
    /// Where the link goes.
    private let paths: Paths

    /// Creates the link's maker.
    public init(files: any FileSystem, paths: Paths) {
        self.files = files
        self.paths = paths
    }

    /// Links to `executable` when nothing is there yet, as Malum does on first start. Returns
    /// whether it made the link; anything already there is left alone for `malum init` to fix.
    public func createIfMissing(to executable: String) throws(SetupError) -> Bool {
        guard files.item(at: paths.commandLink) == nil else { return false }
        try link(to: executable)
        return true
    }

    /// Points the link at `executable`, replacing a link to anywhere else, as `malum init` does.
    public func point(to executable: String) throws(SetupError) -> LinkChange {
        switch files.item(at: paths.commandLink) {
        case nil:
            try link(to: executable)
            return .created
        case .link(let destination) where destination == executable:
            return .unchanged
        case .link(let destination):
            try link(to: executable)
            return .moved(from: destination)
        case .file, .directory:
            throw .occupied(path: paths.commandLink)
        }
    }

    /// Creates the bin folder when needed, then the link.
    private func link(to executable: String) throws(SetupError) {
        do {
            try files.createDirectory(paths.binDirectory)
            try files.link(paths.commandLink, to: executable)
        } catch {
            throw .file(error)
        }
    }
}
