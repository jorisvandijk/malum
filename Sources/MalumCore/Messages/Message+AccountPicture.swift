/// The words for the user's picture `malum.toml` takes from the Apple Account.
extension MessageText {
    /// Making the Apple Account's picture the user's picture.
    static let setAccountPicture: MessageText = "set your user picture to your Apple Account's picture"
}

extension Message {
    /// The Apple Account's picture is the user's picture now.
    static var accountPictureSet: Message {
        Message(.info, "your user picture is your Apple Account's picture now")
    }

    /// No Apple Account is signed in, or macOS hasn't got its picture yet.
    static var noAppleAccountPicture: Message {
        couldnt(
            .setAccountPicture, "no Apple Account picture yet, sign in to your Apple Account in System Settings",
            level: .warn)
    }

    /// `dscl` didn't take the picture, saying `reason`.
    static func accountPictureNotSet(reason: String) -> Message {
        couldnt(.setAccountPicture, "\(reason)")
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
