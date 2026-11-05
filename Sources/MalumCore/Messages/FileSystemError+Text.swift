/// The words for files and the state folder, which every area uses.
extension FileSystemError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreadable(let path, let reason):
            .couldnt("read \(private: path)", "\(reason)")
        case .unwritable(let path, let reason):
            .couldnt("write \(private: path)", "\(reason)")
        case .noDirectory(let path, let reason):
            .couldnt("create \(private: path)", "\(reason)")
        case .unlinkable(let path, let reason):
            .couldnt("link \(private: path)", "\(reason)")
        case .uncopyable(let path, let reason):
            .couldnt("copy \(private: path)", "\(reason)")
        case .unswappable(let path, let other, let reason):
            .couldnt("swap \(private: path) with \(private: other)", "\(reason)")
        case .unremovable(let path, let reason):
            .couldnt("remove \(private: path)", "\(reason)")
        case .unlistable(let path, let reason):
            .couldnt("list \(private: path)", "\(reason)")
        case .userFile(let path):
            "won't write \(private: path): \(Project.name) never writes TOML files"
        }
    }
}

extension StateError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unlockable(let path, let reason):
            .couldnt("lock \(private: path)", "\(reason)")
        case .file(let error):
            error.text
        }
    }
}
