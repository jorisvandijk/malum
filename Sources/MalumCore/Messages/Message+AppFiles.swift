/// The words for the app config files and preferences that system config writes from `apps/` in
/// dots.
extension MessageText {
    /// Writing every app's config files.
    static let writeAppFiles: MessageText = "write app config files"

    /// Setting every app's preferences.
    static let setPreferences: MessageText = "set app preferences"

    /// Installing the extensions VSCodium lists.
    static let installExtensions: MessageText = "install \(vscodiumExtensions)"

    /// A VSCodium extension, as the install and uninstall messages name it.
    static let vscodiumExtension: MessageText = "VSCodium extension"

    /// VSCodium extensions, in the plural.
    static let vscodiumExtensions: MessageText = "VSCodium extensions"

    /// Writing the config files of `app`.
    static func writeAppFiles(of app: String) -> MessageText {
        "write \(app)'s config files"
    }
}

extension Message {
    /// `codium` isn't where the `vscodium` cask links it.
    static var noCodium: Message {
        couldnt(
            .installExtensions,
            "codium isn't installed at \(private: Codium.path), add vscodium = \"cask\" to [homebrew] in \(Paths.packagesTOMLName)"
        )
    }

    /// There's no `apps/` folder at `path`.
    static func noAppsFolder(missing path: String) -> Message {
        Message(.info, "no app config files to write: \(private: path) doesn't exist")
    }

    /// There's a file for `name` in `apps/`, but Malum has no such app.
    static func unknownApp(_ name: String) -> Message {
        Message(.warn, "\(Paths.appFile(named: name)): \(Project.name) has no app called \(name)")
    }

    /// Writing one of `app`'s config files failed.
    static func writeFailed(app: String, _ error: any Error) -> Message {
        failed("write \(app)'s config file", error)
    }

    /// Removing one of `app`'s config files failed.
    static func removeFailed(app: String, _ error: any Error) -> Message {
        failed("remove \(app)'s config file", error)
    }

    /// Every app config file already holds what dots says.
    static var appFilesUpToDate: Message {
        Message(.info, "every app config file is up to date")
    }

    /// The file at `path` already held what `source` says, so Malum took it over.
    static func adopted(file path: String, source: String) -> Message {
        Message(.info, .managesNow("\(private: path) already matched \(source)"))
    }

    /// `path` was written from `source`, where there was nothing before.
    static func wrote(_ path: String, from source: String) -> Message {
        Message(.info, "wrote \(private: path) from \(source)")
    }

    /// `path` was written from `source` in place of a link to `destination`.
    static func wrote(_ path: String, from source: String, replacingLinkTo destination: String) -> Message {
        Message(.info, "wrote \(private: path) from \(source), replacing a link to \(private: destination)")
    }

    /// `path`, which Malum wrote, was deleted, so it was written again from `source`.
    static func wroteAgain(_ path: String, from source: String) -> Message {
        Message(.warn, "\(private: path) was deleted outside \(Project.name), wrote it again from \(source)")
    }

    /// `path` was overwritten from `source` after its old text was kept; `changed` says whether it
    /// was a file Malum wrote that was changed by hand, rather than one that was there already.
    /// `diff` is the command that shows what changed.
    static func overwrote(_ path: String, from source: String, changed: Bool, diff: String) -> Message {
        let why: MessageText =
            changed
            ? "was changed outside \(Project.name), so it was overwritten from"
            : "was already there and differed from"
        return Message(.warn, "\(private: path) \(why) \(source), see what changed with: \(private: diff)")
    }

    /// `path` was brought up to date from `source`.
    static func updated(_ path: String, from source: String) -> Message {
        Message(.info, "updated \(private: path) from \(source)")
    }

    /// `path` isn't written from `source` anymore, but it was changed by hand, so it stays.
    static func keptChanged(_ path: String, source: String) -> Message {
        let subject: MessageText = """
            \(private: path) isn't written from \(source) anymore, but it was changed outside \(Project.name)
            """
        return Message(.warn, .letGo(subject))
    }

    /// `path` was removed, since `source` doesn't write it anymore.
    static func removed(_ path: String, source: String) -> Message {
        Message(.info, "removed \(private: path), \(source) doesn't write it anymore")
    }

    /// Every app preference already holds what dots says.
    static var preferencesUpToDate: Message {
        Message(.info, "every app preference is up to date")
    }

    /// The preference `key` in `domain` was set from `source`.
    static func preferenceSet(_ key: String, in domain: String, from source: String) -> Message {
        Message(.info, "set \(key) in \(domain) from \(source)")
    }

    /// The preference `key` was removed from `domain`, since `source` doesn't set it anymore.
    static func preferenceRemoved(_ key: String, from domain: String, source: String) -> Message {
        Message(.info, "removed \(key) from \(domain), \(source) doesn't set it anymore")
    }

    /// `app` reads its preferences only when it starts.
    static func reopenToApply(_ app: String) -> Message {
        Message(.info, "\(app) reads its preferences when it starts: quit and reopen it to use the new ones")
    }

    /// The preferences in `domain` couldn't be read.
    static func preferencesUnreadable(_ domain: String, reason: String) -> Message {
        couldnt("read the preferences in \(domain)", "\(reason)")
    }

    /// Setting the preference `key` in `domain` failed.
    static func preferenceNotSet(_ key: String, in domain: String, reason: String) -> Message {
        couldnt("set \(key) in \(domain)", "\(reason)")
    }

    /// Removing the preference `key` from `domain` failed.
    static func preferenceNotRemoved(_ key: String, from domain: String, reason: String) -> Message {
        couldnt("remove \(key) from \(domain)", "\(reason)")
    }
}
