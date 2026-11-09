/// The words of `malum samba password`, which keeps a Samba server's password in the login keychain.
extension MessageText {
    /// Storing the password of `account`, as in "couldn't save the password for joris@nas.local".
    static func savePassword(_ account: String) -> MessageText {
        "save the password for \(account)"
    }
}

extension SambaPasswordCommand {
    /// What's asked before `server`'s password is typed.
    public static func prompt(for server: SambaServer) -> String {
        "Password for \(server.account): "
    }
}

extension Message {
    /// The Samba module's own file in dots.
    private static var sambaFile: String { Paths.moduleTOMLName(SambaConfig.module) }

    /// The password of `account` is in the keychain now.
    static func passwordSaved(_ account: String) -> Message {
        Message(.info, "saved the password for \(account) in the login keychain")
    }

    /// Nothing was typed or piped in.
    static var noPasswordEntered: Message {
        couldnt("save the password", "no password was entered")
    }

    /// Dots has no Samba servers, or their settings couldn't be read.
    static var noSambaSettings: Message {
        Message(.error, "found no Samba servers in dots: add a [[server]] to \(sambaFile)")
    }

    /// No server in the settings is called `name`; `known` are the names there are.
    static func noSambaServer(_ name: String, known: [String]) -> Message {
        Message(.error, "\(sambaFile) has no server called \(name), only \(known.joined(separator: ", "))")
    }
}

extension Message {
    /// `path` was unmounted, because its share left the settings.
    static func unmountedDropped(_ path: String) -> Message {
        Message(.info, "unmounted \(private: path), its share is no longer in \(sambaFile)")
    }

    /// `diskutil` couldn't take the share off `path`, for `reason`.
    static func couldntUnmount(_ path: String, _ reason: String) -> Message {
        couldnt("unmount \(private: path)", MessageText(reason))
    }
}

extension ShareState {
    /// What this state of `share` on `server` says in the log and the menu bar.
    func message(_ share: String, on server: SambaServer) -> Message {
        let name = "\(server.name)/\(share)"
        switch self {
        case .mounted(let path):
            return Message(.info, "\(name): mounted at \(private: path)")
        case .unmounted(let path):
            return Message(.info, "\(name): unmounted \(private: path), \(server.host) stopped answering")
        case .unreachable:
            return Message(.info, "\(name): not mounted, \(server.host) doesn't answer")
        case .noPassword:
            return Message(.warn, "\(name): no password, run \(Project.command) samba password \(server.name)")
        case .taken(let path):
            return Message(.warn, "\(name): not mounted, \(private: path) is already taken")
        case .unreadablePassword(let error):
            return .couldnt("read the password for \(server.account)", MessageText(error: error))
        case .failed(let error):
            return .couldnt("mount \(name)", error.text(for: server))
        case .stuck(let path, let reason):
            return .couldnt("unmount \(private: path) after \(server.host) stopped answering", MessageText(reason))
        }
    }
}

extension SambaMountError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .refused: "the server refused the user or password"
        case .noShare: "the server has no share by that name"
        case .noAccess: "the user may not open this share"
        case .noAnswer: "the server didn't answer"
        case .other(let status): "error \(status)"
        }
    }

    /// The problem, with what to do about a refused password on `server`.
    func text(for server: SambaServer) -> MessageText {
        guard self == .refused else { return text }
        return "\(text), run \(Project.command) samba password \(server.name) to change it"
    }
}
