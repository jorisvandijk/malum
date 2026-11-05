/// The words for `malum init` and the command link.
extension Message {
    /// dots was already recorded at `dots`.
    static func dotsAlreadyAt(_ dots: String) -> Message {
        Message(.info, "dots is already at \(private: dots)")
    }

    /// dots was recorded for the first time, at `dots`, in `file`.
    static func dotsSaved(_ dots: String, in file: String) -> Message {
        Message(.info, "dots is at \(private: dots), saved in \(private: file)")
    }

    /// dots was recorded at `dots` in place of `previous`.
    static func dotsMoved(from previous: String, to dots: String) -> Message {
        Message(.info, "dots moved from \(private: previous) to \(private: dots)")
    }

    /// The command link at `link` was made, pointing to `executable`.
    public static func linked(_ link: String, to executable: String) -> Message {
        Message(.info, "linked \(private: link) to \(private: executable)")
    }

    /// The command link at `link` was moved to `executable` from `previous`.
    static func linked(_ link: String, to executable: String, from previous: String) -> Message {
        Message(.info, "linked \(private: link) to \(private: executable), it pointed to \(private: previous)")
    }

    /// The command link at `link` already pointed to `executable`.
    static func alreadyLinked(_ link: String, to executable: String) -> Message {
        Message(.info, "\(private: link) already points to \(private: executable)")
    }
}

// MARK: - ReportableError

extension SetupError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .dotsNotFound(let path):
            .couldnt("use \(private: path) as dots", "folder not found")
        case .occupied(let path):
            .couldnt("link \(private: path)", "something that isn't a link is there, move it away and run init again")
        case .notInApp(let path):
            .couldnt("link \(private: path)", "\(Project.name) isn't running from \(Project.name).app")
        case .file(let error):
            error.text
        }
    }
}
