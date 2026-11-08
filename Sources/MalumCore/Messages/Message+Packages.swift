/// The words for what system config installs: the run itself, the password, Homebrew, the App
/// Store, GitHub releases and the record of what Malum manages.
extension MessageText {
    /// What the run does first, as in "couldn't install packages".
    static let installPackages: MessageText = "install packages"
    /// Installing from the App Store.
    static let installAppStoreApps: MessageText = "install \(appStoreApps)"
    /// Installing GitHub releases.
    static let installReleases: MessageText = "install GitHub releases"
    /// Keeping the record up to date.
    static let recordManaged: MessageText = "record what \(Project.name) manages"
    /// An App Store app, as the install and uninstall messages name it.
    static let appStoreApp: MessageText = "App Store app"
    /// App Store apps, in the plural.
    static let appStoreApps: MessageText = "App Store apps"
    /// A GitHub release, as the install and uninstall messages name it.
    static let release: MessageText = "GitHub release"

    /// What mas needs the password for: installing, uninstalling or both.
    static func changeAppStoreApps(installing: Bool, removing: Bool) -> MessageText {
        let actions = [installing ? "install" : nil, removing ? "uninstall" : nil].compactMap { $0 }
        return "\(actions.joined(separator: " and ")) \(appStoreApps)"
    }
}

extension PackageKind {
    /// The kind as messages name it, with Homebrew in front, so it's clear what a cask is.
    var label: MessageText { "Homebrew \(rawValue)" }

    /// The kind in the plural, as messages name it.
    var plural: MessageText {
        switch self {
        case .formula:
            "Homebrew formulae"
        case .cask:
            "Homebrew casks"
        }
    }
}

extension Message {
    // MARK: - The run

    /// System config's table in `malum.toml`, at `path`, has an error.
    static func systemConfigNeedsFix(in path: String) -> Message {
        couldnt("run \(SystemConfig.id)", "fix its table in \(private: path) first")
    }

    /// System config is switched off in `malum.toml`, at `path`.
    static func systemConfigOff(in path: String) -> Message {
        couldnt("run \(SystemConfig.id)", "it's off, set enabled = true in its table in \(private: path)")
    }

    /// How the run ended.
    static func systemConfigFinished(succeeded: Bool) -> Message {
        if succeeded {
            Message(.info, "\(SystemConfig.id) is done")
        } else {
            Message(.error, "\(SystemConfig.id) finished with errors")
        }
    }

    /// There's no `packages.toml` at `path`.
    static func nothingToInstall(missing path: String) -> Message {
        Message(.info, "nothing to install: \(private: path) doesn't exist")
    }

    /// The dots file at `path` has errors that stop `action`.
    static func needsFix(_ action: MessageText, _ path: String) -> Message {
        couldnt(action, .fixFirst(path))
    }

    // MARK: - The password

    /// `action` needs the password, and there's no terminal to ask in.
    static func passwordNeedsTerminal(for action: MessageText) -> Message {
        couldnt(action, "it needs your password, so run it from a terminal")
    }

    /// sudo is about to ask for the password.
    static func askingForPassword(for action: MessageText) -> Message {
        Message(.info, "asking for your password to \(action)")
    }

    /// sudo didn't get the password.
    static func passwordRefused(for action: MessageText) -> Message {
        couldnt(action, "sudo wasn't granted")
    }

    // MARK: - Installing and uninstalling

    /// `brew` isn't where Homebrew puts it.
    static var noHomebrew: Message {
        couldnt(.installPackages, "Homebrew isn't installed at \(private: Brew.path)")
    }

    /// `mas` isn't where Homebrew puts it.
    static var noMas: Message {
        couldnt(
            .installAppStoreApps,
            "mas isn't installed at \(private: Mas.path), add mas = \"formula\" to [homebrew] in \(Paths.packagesTOMLName)"
        )
    }

    /// What's installed of a kind, named by its `plural`, couldn't be listed.
    static func unlistable(_ plural: MessageText, reason: String) -> Message {
        couldnt("list the installed \(plural)", "\(reason)")
    }

    /// Every listed thing of the kind named `label` is installed.
    static func allInstalled(_ label: MessageText) -> Message {
        Message(.info, "every listed \(label) is installed")
    }

    /// The `label` `name` was installed already, so Malum took it over.
    static func adopted(_ label: MessageText, _ name: String) -> Message {
        Message(.info, .managesNow("\(label) \(name) was already installed"))
    }

    /// The `label` shown as `shown` is being installed.
    static func installing(_ label: MessageText, _ shown: String) -> Message {
        Message(.info, "installing \(label) \(shown)")
    }

    /// The `label` `name` couldn't be installed.
    static func installFailed(_ label: MessageText, _ name: String, reason: String) -> Message {
        couldnt("install \(label) \(name)", "\(reason)")
    }

    /// The `label` `name` is installed.
    static func installed(_ label: MessageText, _ name: String) -> Message {
        Message(.info, "installed \(label) \(name)")
    }

    /// The `label` `name` that Malum managed was uninstalled by someone else.
    static func alreadyUninstalled(_ label: MessageText, _ name: String) -> Message {
        Message(.info, "\(label) \(name) was already uninstalled")
    }

    /// The `label` shown as `shown` is being uninstalled.
    static func uninstalling(_ label: MessageText, _ shown: String) -> Message {
        Message(.info, "uninstalling \(label) \(shown)")
    }

    /// The `label` `name` is uninstalled.
    static func uninstalled(_ label: MessageText, _ name: String) -> Message {
        Message(.info, "uninstalled \(label) \(name)")
    }

    /// The `label` `name` is still needed, so it stays.
    static func stillNeeded(_ label: MessageText, _ name: String) -> Message {
        Message(.warn, .letGo("\(label) \(name) is still needed by other packages"))
    }

    /// The `label` `name` couldn't be uninstalled.
    static func uninstallFailed(_ label: MessageText, _ name: String, reason: String) -> Message {
        couldnt("uninstall \(label) \(name)", "\(reason)")
    }

    // MARK: - GitHub releases

    /// The release `name` at `tag` is being installed from the file `asset`.
    static func installing(release name: String, tag: String, asset: String) -> Message {
        installing(.release, "\(name) \(tag) (\(asset))")
    }

    /// The release `name` at `tag` is installed at `path`.
    static func installed(release name: String, tag: String, at path: String) -> Message {
        Message(.info, "installed \(MessageText.release) \(name) \(tag) at \(private: path)")
    }

    /// The release `name` was removed from `path`.
    static func removed(release name: String, from path: String) -> Message {
        Message(.info, "removed \(MessageText.release) \(name) from \(private: path)")
    }

    /// A release replaced what was already at `path`, which Malum didn't install.
    static func takenOver(release path: String) -> Message {
        Message(.info, .managesNow("\(private: path) was already there and was replaced"))
    }

    /// The release `name` couldn't be installed.
    static func installFailed(release name: String, _ error: any Error) -> Message {
        failed("install \(MessageText.release) \(name)", error)
    }

    /// The release `name` couldn't be removed.
    static func removeFailed(release name: String, _ error: any Error) -> Message {
        failed("remove \(MessageText.release) \(name)", error)
    }

    /// Every listed release is installed at its latest version.
    static var releasesUpToDate: Message {
        Message(.info, "every listed \(MessageText.release) is up to date")
    }
}

// MARK: - ReportableError

extension RecordError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .unreadable(let path):
            "couldn't read \(private: path), the record of what \(Project.name) installed"
        case .unwritable(let reason):
            .couldnt("write the record of what \(Project.name) installed", "\(reason)")
        case .notUTF8:
            .couldnt("write the record of what \(Project.name) installed", "it isn't UTF-8")
        }
    }
}

extension ReleaseError {
    /// The files `release` of `repo` has, for a message that says which file to install.
    static func found(in release: Release, of repo: String) -> String {
        let names = release.assets.map { "\"\($0.name)\"" }.joined(separator: ", ")
        return "\(repo) \(release.tag) has \(names.isEmpty ? "no files" : names)"
    }
}

extension ReleaseError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .noRelease(let repo):
            "\(repo) has no published release on GitHub, or it's private"
        case .assetMatches(let count, let pattern, let found):
            "\(count) files match \"\(pattern)\"; \(found)"
        case .unclearAsset(let table, let found):
            "can't tell which file to install, set asset in [\(table)]; \(found)"
        case .installer(let name):
            "\"\(name)\" is an installer, which \(Project.name) can't install"
        case .unpackable(let path, let reason):
            .couldnt("unpack \(private: path)", "\(reason)")
        case .nestedArchives:
            "it holds archives inside archives"
        case .severalApps(let name):
            "it holds several apps, and none is called \(name).app"
        case .severalPrograms(let name):
            "it holds several programs, and none is called \(name)"
        case .nothingToInstall:
            "it holds no app or program"
        case .taken(let path, let owner):
            "\(private: path) is where \(MessageText.release) \(owner) is installed"
        }
    }
}

extension GitHubError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreachable(let reason):
            .couldnt("reach GitHub", "\(reason)")
        case .notALink(let address):
            .couldnt("reach GitHub", "\(address) isn't a link")
        case .refused(let status):
            "GitHub answered with HTTP \(status)"
        case .unreadable:
            "GitHub sent an answer \(Project.name) can't read"
        case .unsaved(let path, let reason):
            .couldnt("save \(private: path)", "\(reason)")
        case .tokenRefused:
            "GitHub refused the token, run \(Project.command) token with a new one"
        case .tokenCantRead(let repo):
            "the token can't read \(repo), give it access to that repository on GitHub"
        case .needsToken(let repo):
            "GitHub shows \(repo) only with a token, run \(Project.command) token"
        }
    }
}
