/// The shapes every message is built from, so each area words its messages the same way.
extension MessageText {
    /// `couldn't <action>: <reason>`, the shape of every failure.
    static func couldnt(_ action: MessageText, _ reason: MessageText) -> MessageText {
        "couldn't \(action): \(reason)"
    }

    /// `fix <path> first`, the reason when a dots file has errors that stop the work.
    static func fixFirst(_ path: String) -> MessageText {
        "fix \(private: path) first"
    }

    /// `<subject>, <Malum> manages it now`, for something already in place that Malum takes over.
    static func managesNow(_ subject: MessageText) -> MessageText {
        "\(subject), \(Project.name) manages it now"
    }

    /// `<subject>, so it stays and <Malum> no longer manages it`, for something Malum lets go of
    /// without removing it.
    static func letGo(_ subject: MessageText) -> MessageText {
        "\(subject), so it stays and \(Project.name) no longer manages it"
    }
}

extension Message {
    /// `[error] couldn't <action>: <reason>`, or at another level when it isn't an error.
    static func couldnt(_ action: MessageText, _ reason: MessageText, level: Level = .error) -> Message {
        Message(level, .couldnt(action, reason))
    }

    /// `[error] couldn't <action>: <the error's own text>`.
    static func failed(_ action: MessageText, _ error: any Error) -> Message {
        couldnt(action, MessageText(error: error))
    }

    /// The error's own text as an error message, for errors that already say what failed.
    public static func failed(_ error: any Error) -> Message {
        Message(.error, MessageText(error: error))
    }

    /// The error's own text as a warning, for errors that already say what failed and don't stop the work.
    public static func warning(_ error: any Error) -> Message {
        Message(.warn, MessageText(error: error))
    }
}
