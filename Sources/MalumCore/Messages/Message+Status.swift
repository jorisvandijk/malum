/// The words of `malum status`, which shows what Malum manages and what doesn't match dots.
extension MessageText {
    /// Showing the status, as in "couldn't show the status".
    static let showStatus: MessageText = "show the status"
    /// GitHub releases, in the plural.
    static let releases: MessageText = "GitHub releases"
    /// The app config files Malum wrote from `apps/`.
    static let appFiles: MessageText = "app config files"
    /// The app preferences Malum set from `apps/`.
    static let appPreferences: MessageText = "app preferences"
    /// The macOS settings Malum set from `macos.toml`.
    static let macOSSettings: MessageText = "macOS settings"
    /// The files only root can change that Malum wrote from `macos.toml`.
    static let systemFiles: MessageText = "files only root can change"
    /// The power settings Malum set from `macos.toml`.
    static let powerSettings: MessageText = "power settings"

    /// What `malum run` does, as the status says it: `malum run <does>`.
    fileprivate static func run(_ does: MessageText) -> MessageText {
        "\(Project.command) run \(does)"
    }
}

extension Message {
    /// There's no dots folder to compare with yet.
    static var statusNoDots: Message {
        couldnt(.showStatus, "no dots folder yet, run \(Project.command) init")
    }

    /// Malum manages `count` of what `plural` names.
    static func statusManaged(_ count: Int, _ plural: MessageText) -> Message {
        Message(.info, "managed \(plural): \(count)")
    }

    /// The listed `label` `name` isn't installed.
    static func statusNotInstalled(_ label: MessageText, _ name: String) -> Message {
        Message(.warn, "\(label) \(name) isn't installed, \(MessageText.run("installs it"))")
    }

    /// The `label` `name` that Malum manages isn't listed anymore.
    static func statusNotListed(_ label: MessageText, _ name: String) -> Message {
        Message(.warn, "\(label) \(name) isn't listed anymore, \(MessageText.run("uninstalls it"))")
    }

    /// The file Malum wrote at `path` is gone.
    static func statusMissing(_ path: String) -> Message {
        Message(.warn, "\(private: path) is missing, \(MessageText.run("writes it again"))")
    }

    /// The file Malum wrote at `path` was changed since.
    static func statusChanged(_ path: String) -> Message {
        let fix = MessageText.run("overwrites it and keeps a .backup")
        return Message(.warn, "\(private: path) was changed outside \(Project.name), \(fix)")
    }

    /// The power setting `setting` on `source` power is `now`, or isn't there, while Malum set it to `value`.
    static func statusPowerChanged(_ setting: String, on source: String, now: Int?, set value: Int) -> Message {
        let holds: MessageText = now.map { "is \($0)" } ?? "isn't there"
        let fix = MessageText.run("sets it back")
        return Message(.warn, "\(setting) on \(source) power \(holds), \(Project.name) set it to \(value), \(fix)")
    }

    /// Everything Malum manages matches dots.
    static var statusMatches: Message {
        Message(.info, "everything \(Project.name) manages matches dots")
    }
}
