/// The words of `malum token`, which keeps the GitHub token in the login keychain.
extension MessageText {
    /// Storing the token, as in "couldn't save the GitHub token".
    static let saveToken: MessageText = "save the GitHub token"
    /// Removing the token, as in "couldn't remove the GitHub token".
    static let removeToken: MessageText = "remove the GitHub token"
    /// Reading the token, as in "couldn't read the GitHub token".
    static let readToken: MessageText = "read the GitHub token"
}

extension TokenCommand {
    /// What `malum token` asks before the token is typed.
    public static let prompt = "GitHub token: "
}

extension Message {
    /// The token is in the keychain now.
    static var tokenSaved: Message {
        Message(.info, "saved the GitHub token in the login keychain")
    }

    /// The token is gone from the keychain.
    static var tokenRemoved: Message {
        Message(.info, "removed the GitHub token from the login keychain")
    }

    /// There was no token to remove.
    static var noTokenStored: Message {
        Message(.info, "the login keychain holds no GitHub token")
    }

    /// Nothing was typed or piped in.
    static var noTokenEntered: Message {
        couldnt(.saveToken, "no token was entered")
    }

    /// Whether a token is `stored`, for `malum status`.
    static func tokenStatus(stored: Bool) -> Message {
        let state: MessageText =
            stored ? "stored in the login keychain" : "none, run \(Project.command) token to add one"
        return Message(.info, "GitHub token: \(state)")
    }

    /// The token couldn't be read, so GitHub is asked without it.
    public static func tokenUnreadable(_ error: any Error) -> Message {
        couldnt(.readToken, MessageText(error: error), level: .warn)
    }
}

extension TokenStoreError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .keychain(let status, let reason):
            "the login keychain answered \(reason ?? "error \(status)")"
        }
    }
}
