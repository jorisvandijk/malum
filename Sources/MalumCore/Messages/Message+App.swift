/// The words for the app itself: starting, signing, starting at login, safe mode after a crash
/// loop, watching `malum.toml`, and the command line's arguments.
extension Message {
    /// This app started.
    public static var running: Message {
        Message(.info, "\(Project.name) \(Project.version) is running")
    }

    /// Another app already runs, so this one quits.
    public static var alreadyRunning: Message {
        Message(.info, "\(Project.name) is already running")
    }

    /// Safe mode turned itself on, because the app keeps starting.
    public static var crashLoop: Message {
        Message(.warn, "\(SafeModeReason.crashLoop), so safe mode is on and every module stays off")
    }

    /// The login agent was written to `path`.
    public static func startsAtLogin(through path: String) -> Message {
        Message(.info, "\(Project.name) starts at login, through \(private: path)")
    }

    /// No login agent, because the app doesn't run from `installed`.
    public static func notStartingAtLogin(installed: String) -> Message {
        Message(.info, "not starting at login: \(Project.name) isn't running from \(private: installed)")
    }

    /// The app was signed with its own certificate and starts again.
    public static var resigned: Message {
        Message(.info, "signed \(Project.name) with the \"\(SigningCertificate.name)\" certificate, restarting")
    }

    /// The modules stay off, because the app doesn't run from `installed`.
    public static func modulesOff(installed: String) -> Message {
        Message(.warn, "modules stay off: \(Project.name) isn't running from \(private: installed)")
    }

    /// The folder `malum.toml` is in can't be watched, so changes need a reload.
    public static func unwatchable(_ folder: String) -> Message {
        Message(.warn, "couldn't watch \(private: folder), run \(Project.command) reload after a change")
    }

    /// `command` is missing what it `needs`.
    public static func incomplete(_ command: String, needs: String) -> Message {
        Message(.error, "\(command) needs \(needs)")
    }

    /// The command line has an argument that isn't known.
    public static func unknownArgument(_ argument: String) -> Message {
        Message(.error, "unknown argument: \(argument)")
    }

    /// The docs tool wrote the page at `path`.
    public static func wrote(_ path: String) -> Message {
        Message(.info, "wrote \(path)")
    }
}

// MARK: - ReportableError

extension SigningError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        let certificate = "the \"\(SigningCertificate.name)\" certificate"
        return switch self {
        case .uncreatable(let step, let reason):
            .couldnt("\(step) for \(certificate)", "\(reason)")
        case .unlisted:
            "added \(certificate) to the login keychain, but codesign doesn't list it"
        case .files(let error):
            error.text
        case .unsigned(let reason):
            .couldnt("sign \(Project.name) with \(certificate)", "\(reason)")
        case .unverified(let reason):
            "the signed copy of \(Project.name) didn't pass codesign's check: \(reason)"
        case .unrestartable(let reason):
            .couldnt("restart \(Project.name)", "\(reason); quit it and open it again")
        }
    }
}
