/// The words for the macOS settings that system config sets from `macos.toml` in dots.
extension MessageText {
    /// Setting macOS's settings.
    static let setMacOSSettings: MessageText = "set macOS settings"
}

extension Message {
    /// There's no `macos.toml` at `path`, so no macOS setting is touched.
    static func noMacOSSettings(missing path: String) -> Message {
        Message(.info, "no macOS settings to set: \(private: path) doesn't exist")
    }

    /// Every macOS setting already holds what dots says.
    static var macOSUpToDate: Message {
        Message(.info, "every macOS setting is up to date")
    }

    /// `process` was restarted so it shows the changed settings.
    static func restarted(_ process: String) -> Message {
        Message(.info, "restarted \(process) to use the new settings")
    }

    /// `process` couldn't be restarted.
    static func notRestarted(_ process: String, reason: String) -> Message {
        couldnt("restart \(process)", "\(reason)", level: .warn)
    }

    /// Running apps couldn't be told about the changed settings.
    static func notActivated(reason: String) -> Message {
        couldnt("tell running apps about the new settings", "\(reason)", level: .warn)
    }

    /// A changed setting may only show after logging out.
    static var logOutToApply: Message {
        Message(.info, "some macOS settings, such as key repeat, take full effect after you log out and back in")
    }
}
