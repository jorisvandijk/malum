/// The words for Malum updating itself and rolling back.
extension MessageText {
    /// Updating the app, as in "couldn't update Malum".
    static let updateApp: MessageText = "update \(Project.name)"
    /// Rolling the app back, as in "couldn't roll back Malum".
    static let rollBackApp: MessageText = "roll back \(Project.name)"
}

extension SelfUpdate {
    /// What a version that can't be read is called.
    static let unknownVersion = "an unknown version"
}

extension Message {
    /// No update, because the app doesn't run from `installed`.
    static func noSelfUpdate(notInstalled installed: String) -> Message {
        Message(.info, "not updating: \(Project.name) isn't running from \(private: installed)")
    }

    /// No update, because the running app is a `build` build, not a release.
    static func noSelfUpdate(build: String) -> Message {
        Message(.info, "not updating: this is a \(build) build of \(Project.name), not a release")
    }

    /// The running version is the latest release.
    static func upToDate(_ version: Version) -> Message {
        Message(.info, "\(Project.name) \(version.description) is up to date")
    }

    /// The latest release is older than the running version, and isn't installed without `--force`.
    static func releaseIsOlder(latest: Version, running: Version) -> Message {
        Message(
            .warn,
            """
            the latest release, \(latest.description), is older than \(Project.name) \(running.description); \
            run \(Project.command) run --force to install it
            """)
    }

    /// The update to `version` starts.
    static func updating(from running: Version, to version: Version) -> Message {
        Message(.info, "updating \(Project.name) \(running.description) to \(version.description)")
    }

    /// The app is now `version`, and `kept` is kept for a rollback.
    static func updated(to version: Version, kept: Version) -> Message {
        Message(
            .info,
            """
            updated \(Project.name) to \(version.description); \
            \(Project.command) rollback puts \(kept.description) back
            """)
    }

    /// The update went in, but the version it replaced couldn't be kept.
    static func previousNotKept(_ error: any Error) -> Message {
        couldnt("keep the previous version for a rollback", MessageText(error: error), level: .warn)
    }

    /// The app is back at `version`, and `kept` is kept for the next rollback.
    static func rolledBack(to version: String, kept: String) -> Message {
        Message(.info, "rolled back \(Project.name) to \(version); \(Project.command) rollback puts \(kept) back")
    }
}

// MARK: - ReportableError

extension UpdateError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreadableTag(let tag):
            "the latest release's tag, \"\(tag)\", isn't a version"
        case .missingAsset(let name, let tag):
            "release \(tag) has no \(name)"
        case .uncheckable(let reason):
            .couldnt("check the download's checksum", "\(reason)")
        case .checksumMismatch(let name):
            "\(name) doesn't match its checksum"
        case .unpackable(let reason):
            .couldnt("unpack the download", "\(reason)")
        case .noApp(let name):
            "\(name) doesn't hold \(Project.name).app"
        case .otherApp(let bundleID):
            "the downloaded app is \(bundleID ?? "missing its bundle ID"), not \(Project.bundleID)"
        case .wrongVersion(let expected, let found):
            "the downloaded app says it's \(found), not \(expected)"
        case .noCertificate:
            "the login keychain doesn't have the \"\(SigningCertificate.name)\" certificate"
        case .nothingKept:
            "no previous version is kept"
        case .keptUnsigned:
            "the kept version isn't signed with the \"\(SigningCertificate.name)\" certificate"
        }
    }
}
