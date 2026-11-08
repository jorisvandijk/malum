/// The words for the macOS settings that system config sets from `macos.toml` in dots.
extension MessageText {
    /// Setting macOS's settings.
    static let setMacOSSettings: MessageText = "set macOS settings"
    /// Changing the files only root can change.
    static let changeSystemFiles: MessageText = "change \(SystemFile.hosts.path) or Touch ID for sudo"
    /// Changing the power settings.
    static let changePower: MessageText = "change power settings"
    /// Removing the Apple apps `macos.toml` lists.
    static let removeAppleApps: MessageText = "remove Apple apps"
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

    /// `path` was set back to macOS's own, since `source` doesn't set it anymore.
    static func putBack(_ path: String, source: String) -> Message {
        Message(.info, "put back macOS's own \(path), \(source) doesn't set it anymore")
    }

    /// The file at `path` couldn't be changed as root.
    static func systemFileNotChanged(_ path: String, reason: String) -> Message {
        couldnt("change \(path)", "\(reason)")
    }

    /// macOS couldn't be made to read `/etc/hosts` again.
    static func hostsNotReread(reason: String) -> Message {
        couldnt("make macOS read \(SystemFile.hosts.path) again", "\(reason)", level: .warn)
    }

    /// The power settings couldn't be read.
    static func powerUnreadable(reason: String) -> Message {
        couldnt("read the power settings", "\(reason)")
    }

    /// This Mac has no `source` power, such as a battery, so its settings were skipped.
    static func noPowerSource(_ source: String) -> Message {
        Message(.warn, "this Mac has no \(source) power, so [power.\(source)] in \(Paths.macOSTOMLName) was skipped")
    }

    /// `pmset` has no `setting` on `source` power.
    static func noPowerSetting(_ setting: String, on source: String) -> Message {
        couldnt("set \(setting) on \(source) power", "pmset has no such setting, pmset -g custom lists them")
    }

    /// `setting` on `source` power was set to `value` from `macos.toml`; it was `was`.
    static func powerSet(_ setting: String, on source: String, to value: Int, was: Int) -> Message {
        Message(.info, "set \(setting) on \(source) power to \(value) from \(Paths.macOSTOMLName) (it was \(was))")
    }

    /// `setting` on `source` power went back to `value`, since `macos.toml` doesn't set it anymore.
    static func powerPutBack(_ setting: String, on source: String, to value: Int) -> Message {
        Message(
            .info, "set \(setting) on \(source) power back to \(value), \(Paths.macOSTOMLName) doesn't set it anymore")
    }

    /// `setting` on `source` power isn't set from `macos.toml` anymore, but it was changed by hand.
    static func powerKeptChanged(_ setting: String, on source: String) -> Message {
        let subject: MessageText = """
            \(setting) on \(source) power isn't set from \(Paths.macOSTOMLName) anymore, but it was changed \
            outside \(Project.name)
            """
        return Message(.warn, .letGo(subject))
    }

    /// `setting` on `source` power couldn't be set.
    static func powerNotSet(_ setting: String, on source: String, reason: String) -> Message {
        couldnt("set \(setting) on \(source) power", "\(reason)")
    }

    /// The Apple app at `path` was removed.
    static func removedAppleApp(_ path: String) -> Message {
        Message(.info, "removed \(path), it's in [apple_apps] remove in \(Paths.macOSTOMLName)")
    }

    /// The app at `path` isn't Apple's, by its `bundleID`, or it has none, so it stays.
    static func notAppleApp(_ path: String, bundleID: String?) -> Message {
        let why: MessageText = bundleID.map { "its bundle ID is \($0)" } ?? "it has no bundle ID"
        return couldnt("remove \(path)", "it isn't an Apple app, \(why)")
    }

    /// The Apple app at `path` couldn't be removed.
    static func appleAppNotRemoved(_ path: String, reason: String) -> Message {
        couldnt("remove \(path)", "\(reason)")
    }
}
