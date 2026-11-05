/// The words for reaching the running app: `malum reload`, `malum safe` and `malum disable`.
extension Message {
    /// The running app was sent the signal to reload.
    static var askedToReload: Message {
        Message(.info, "asked \(Project.name) to reload")
    }

    /// The app isn't running, so an override waits for its next start.
    static var takesEffectAtStart: Message {
        Message(.info, "\(Project.name) isn't running, so this takes effect when it starts")
    }

    /// `malum safe` turned safe mode on.
    static var safeModeOn: Message {
        Message(.info, "safe mode is on: every module stays off until you leave it from the menu bar")
    }

    /// `malum disable` keeps `module` off.
    static func staysOff(_ module: String) -> Message {
        Message(.info, "\(module) stays off until you enable it from the menu bar")
    }
}

// MARK: - ReportableError

extension InstanceError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .notRunning:
            .couldnt("reach \(Project.name)", "it isn't running")
        case .noProcessID(let path):
            .couldnt("reach \(Project.name)", "no process ID in \(private: path)")
        case .unsignalable(let processID, let reason):
            .couldnt("signal \(Project.name) (process \(processID))", "\(reason)")
        case .state(let error):
            error.text
        }
    }
}
