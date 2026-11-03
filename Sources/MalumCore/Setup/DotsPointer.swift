/// The record of where dots is checked out, the one thing Malum keeps outside dots.
public struct DotsPointer: Sendable {
    /// The disk.
    private let files: any FileSystem
    /// Where the record lives.
    private let paths: Paths

    /// Creates the record's reader and writer.
    public init(files: any FileSystem, paths: Paths) {
        self.files = files
        self.paths = paths
    }

    /// The dots folder, or nil when `malum init` hasn't run.
    public func read() throws(FileSystemError) -> String? {
        guard files.item(at: paths.configFile) != nil else { return nil }
        let path = try files.read(paths.configFile).trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }

    /// Records `dots` as the dots folder.
    public func write(_ dots: String) throws(FileSystemError) {
        try files.createDirectory(paths.configDirectory)
        try files.write(dots + "\n", to: paths.configFile)
    }
}
