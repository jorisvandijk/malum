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
