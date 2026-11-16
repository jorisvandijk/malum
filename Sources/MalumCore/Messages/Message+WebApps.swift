/// What making the web apps does, for its failures.
extension MessageText {
    /// Making the web apps `webapps.toml` lists.
    static let makeWebApps: MessageText = "make the web apps"
}

/// The messages of the web apps `malum run` makes from `webapps.toml`.
extension Message {
    /// Made the web app `name` in `~/Applications`.
    static func madeWebApp(_ name: String) -> Message {
        Message(.info, "made the web app \(name)")
    }

    /// Built the web app `name` again, since its site, icon or Malum changed.
    static func updatedWebApp(_ name: String) -> Message {
        Message(.info, "updated the web app \(name)")
    }

    /// Removed the web app `name`, which `webapps.toml` no longer lists.
    static func removedWebApp(_ name: String) -> Message {
        Message(.info, "removed the web app \(name), which \(Paths.webAppsTOMLName) no longer lists")
    }

    /// The web app `name` couldn't be made.
    static func couldntMakeWebApp(_ name: String, _ error: any Error) -> Message {
        failed("make the web app \(name)", error)
    }

    /// The installed app has no web app executable at `path` to copy.
    static func noWebAppExecutable(_ path: String) -> Message {
        couldnt(.makeWebApps, "\(private: path) is missing, install \(Project.name) from a release")
    }

    /// There's no signing certificate for the web apps yet.
    static let noCertificateForWebApps = couldnt(
        .makeWebApps, "there's no \"\(SigningCertificate.name)\" certificate yet, start \(Project.name) once to make it"
    )
}

// MARK: - ReportableError

/// The words for why a web app couldn't be made.
extension WebAppError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .inTheWay(let path):
            "another app is at \(private: path)"
        case .icon(let reason):
            .couldnt("turn the icon into an app icon", "\(reason)")
        case .files(let error):
            error.text
        case .signing(let error):
            error.text
        }
    }
}
