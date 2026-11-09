/// The words for starting and stopping modules, and for the permissions they wait for.
extension Message {
    /// `module` started.
    static func started(_ module: String) -> Message {
        Message(.info, "started \(module)")
    }

    /// `module` stopped.
    static func stopped(_ module: String) -> Message {
        Message(.info, "stopped \(module)")
    }

    /// `module` set up again what macOS may have dropped, such as after the Mac woke.
    static func resumed(_ module: String) -> Message {
        Message(.info, "set up \(module) again")
    }

    /// Starting `module` failed.
    static func startFailed(_ module: String, _ error: any Error) -> Message {
        failed("start \(module)", error)
    }

    /// Giving `module` its new settings failed.
    static func applyFailed(_ module: String, _ error: any Error) -> Message {
        failed("apply \(module) settings", error)
    }

    /// `module`'s cleanup failed, which doesn't stop the others.
    static func cleanUpFailed(_ module: String, _ error: any Error) -> Message {
        couldnt("clean up after \(module)", MessageText(error: error), level: .warn)
    }

    /// `module` waits until it has `missing`.
    static func waiting(_ module: String, for missing: Set<Permission>) -> Message {
        couldnt("start \(module) yet", "it \(ModuleStatus.needsPermission(missing))", level: .warn)
    }

    // MARK: - The terminal's permissions

    /// `malum permissions` runs outside a terminal.
    static var noTerminal: Message {
        Message(.info, "not running in a terminal, so there's no terminal to check")
    }

    /// `terminal` has Full Disk Access.
    static func hasFullDiskAccess(_ terminal: String) -> Message {
        Message(.info, "\(terminal) has \(Permission.fullDiskAccess)")
    }

    /// `terminal` lacks Full Disk Access, with how to turn it on.
    static func lacksFullDiskAccess(_ terminal: String) -> Message {
        let access = Permission.fullDiskAccess
        return Message(
            .warn,
            """
            \(terminal) doesn't have \(access), so macOS keeps asking \(terminal) about what \(Project.command) \
            does in it; turn it on in System Settings > Privacy & Security > \(access), then quit and reopen \(terminal)
            """)
    }

    /// Whether `terminal` has Full Disk Access couldn't be told.
    static func unknownFullDiskAccess(_ terminal: String) -> Message {
        Message(.warn, "couldn't tell whether \(terminal) has \(Permission.fullDiskAccess)")
    }

    /// System Settings was opened at `permission`'s page.
    public static func openedSettings(at permission: Permission) -> Message {
        Message(.info, "opened System Settings at \(permission)")
    }

    /// System Settings couldn't be opened at `permission`'s page.
    public static func settingsUnopenable(at permission: Permission) -> Message {
        Message(.warn, "couldn't open System Settings at \(permission)")
    }
}
