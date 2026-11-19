/// The words for the user picture `malum.toml` picks.
extension MessageText {
    /// Making a picture from dots the user's picture.
    static let setUserPicture: MessageText = "set your user picture"
}

extension Message {
    /// The picture `file` from dots is the user's picture now.
    static func userPictureSet(_ file: String) -> Message {
        Message(.info, "set your user picture to \(file) from \(Paths.picturesFolderName) in dots")
    }

    /// No picture called `name` is in `folder`.
    static func noUserPicture(_ name: String, in folder: String) -> Message {
        couldnt(.setUserPicture, "there's no picture called \(name) in \(private: folder)")
    }

    /// `dscl` or `dsimport` didn't take the picture, saying `reason`.
    static func userPictureNotSet(reason: String) -> Message {
        couldnt(.setUserPicture, "\(reason)")
    }
}

/// The words for why a square picture couldn't be made.
extension PictureError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreadable(let path):
            "\(private: path) isn't a picture macOS can read"
        case .notMade(let path):
            "macOS couldn't make a square picture from \(private: path)"
        }
    }
}
