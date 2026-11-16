import Foundation

/// Makes the web apps `webapps.toml` lists in `~/Applications`, each a copy of the web app executable
/// in the running app with its own `Info.plist` and icon, signed with Malum's certificate so it
/// keeps its cookies and permissions. A web app whose site, icon or executable changed is built
/// again; one that's no longer listed is removed. Other apps are never touched.
@MainActor
struct WebAppInstaller {
    /// The folder in the state folder where bundles are put together before they're signed.
    private static let stagingName = "webapps"

    /// The disk.
    private let files: any FileSystem
    /// Runs `sips` and `codesign`.
    private let runner: any CommandRunner
    /// Where the web apps and the installed app are.
    private let paths: Paths
    /// Where bundles are put together.
    private let state: StateFolder
    /// Malum's signing certificate.
    private let certificate: SigningCertificate
    /// The web app executable every web app is a copy of.
    private let executable: String

    /// Creates the part.
    init(
        files: any FileSystem, runner: any CommandRunner, paths: Paths, state: StateFolder,
        certificate: SigningCertificate, executable: String
    ) {
        self.files = files
        self.runner = runner
        self.paths = paths
        self.state = state
        self.certificate = certificate
        self.executable = executable
    }

    /// Makes the web apps `webapps.toml` in the dots folder `dots` lists, and removes the ones it
    /// doesn't. No file lists none. Says whether it all worked.
    func run(dots: String, report: (Message) -> Void) async -> Bool {
        let file = paths.webAppsTOML(in: dots)
        let apps: [WebApp]
        do {
            let reading = WebAppList.read(try files.text(ifFileAt: file) ?? "")
            reading.problems.map(\.message).forEach(report)
            guard let read = reading.apps else {
                report(.needsFix(.makeWebApps, file))
                return false
            }
            apps = read
        } catch {
            report(.failed(.makeWebApps, error))
            return false
        }
        let removed = removeUnlisted(apps, report: report)
        guard !apps.isEmpty else { return removed }
        guard files.item(at: executable) == .file else {
            report(.noWebAppExecutable(executable))
            return false
        }
        guard let identity = await certificate.find() else {
            report(.noCertificateForWebApps)
            return false
        }
        var made = removed
        for app in apps {
            made = await make(app, dots: dots, identity: identity, report: report) && made
        }
        return made
    }

    /// Makes `app`, or builds it again when what it's built from changed. Says whether it worked.
    private func make(_ app: WebApp, dots: String, identity: SigningIdentity, report: (Message) -> Void) async -> Bool {
        let bundle = app.bundle(paths)
        do throws(WebAppError) {
            let icon = app.icon.map { "\(dots)/\($0)" }
            let plist = try infoPlist(of: app, icon: icon)
            let existing = files.item(at: bundle) != nil
            if existing, try await isCurrent(app, at: bundle, plist: plist, identity: identity) { return true }
            let staged = try await stage(plist, icon: icon, name: app.name)
            try await install(staged, at: bundle, identity: identity)
            let message: Message = if existing { .updatedWebApp(app.name) } else { .madeWebApp(app.name) }
            report(message)
            return true
        } catch {
            report(.couldntMakeWebApp(app.name, error))
            return false
        }
    }

    /// Whether the bundle at `bundle` is `app` as `plist` describes it, signed with `identity`. A
    /// bundle whose signing failed part way isn't, so it's built again. Throws when another app is there.
    private func isCurrent(
        _ app: WebApp, at bundle: String, plist: String, identity: SigningIdentity
    ) async throws(WebAppError) -> Bool {
        guard AppBundle.bundleID(of: bundle, files: files) == app.bundleID else { throw .inTheWay(path: bundle) }
        let current = try onDisk { () throws(FileSystemError) in try files.text(ifFileAt: Paths.info(of: bundle)) }
        guard current == plist else { return false }
        return await BundleSigner(runner: runner, files: files, tool: paths.signingTool).isSigned(bundle, by: identity)
    }

    /// `app`'s `Info.plist`, with a fingerprint of the executable and of the `icon` file.
    private func infoPlist(of app: WebApp, icon: String?) throws(WebAppError) -> String {
        let program = try onDisk { () throws(FileSystemError) in try files.data(at: executable) }
        let picture = try icon.map { path throws(WebAppError) in
            try onDisk { () throws(FileSystemError) in try files.data(at: path) }
        }
        let source = [Fingerprint.of(program), picture.map(Fingerprint.of) ?? ""].joined(separator: "-")
        return app.infoPlist(source: source)
    }

    /// Puts the bundle together in the state folder: the executable, `plist` and the icon made from
    /// `icon`. Gives its path.
    private func stage(_ plist: String, icon: String?, name: String) async throws(WebAppError) -> String {
        let bundle = "\(state.path(of: Self.stagingName))/\(name).app"
        let resources = Paths.resources(of: bundle)
        try onDisk { () throws(FileSystemError) in
            if files.item(at: bundle) != nil { try files.remove(bundle) }
            try files.createDirectory(Paths.executableFolder(of: bundle))
            try files.createDirectory(resources)
            try files.copy(executable, to: "\(Paths.executableFolder(of: bundle))/\(WebAppInfo.executable)")
            try files.write(plist, to: Paths.info(of: bundle))
        }
        guard let icon else { return bundle }
        let target = "\(resources)/\(WebApp.iconName).\(WebApp.iconExtension)"
        guard !icon.lowercased().hasSuffix(".\(WebApp.iconExtension)") else {
            try onDisk { () throws(FileSystemError) in try files.copy(icon, to: target) }
            return bundle
        }
        let converted = await runner.run(Sips.icon(from: icon, to: target))
        guard converted.succeeded else { throw .icon(reason: converted.reason) }
        return bundle
    }

    /// Signs `staged` and puts it at `bundle`, then removes the staged copy.
    private func install(_ staged: String, at bundle: String, identity: SigningIdentity) async throws(WebAppError) {
        try onDisk { () throws(FileSystemError) in
            if files.item(at: bundle) == nil { try files.copy(staged, to: bundle) }
        }
        do {
            try await BundleSigner(runner: runner, files: files, tool: paths.signingTool).install(
                staged, at: bundle, identity: identity)
        } catch {
            throw .signing(error)
        }
        try onDisk { () throws(FileSystemError) in try files.remove(staged) }
    }

    /// Removes every web app in `~/Applications` that `apps` doesn't list, by bundle ID, so other apps
    /// are never touched. Says whether it worked.
    private func removeUnlisted(_ apps: [WebApp], report: (Message) -> Void) -> Bool {
        let listed = Set(apps.map(\.bundleID))
        let names = (try? files.contents(of: paths.userApplications)) ?? []  // No folder: no web apps.
        var removed = true
        for name in names.sorted() where name.hasSuffix(".app") {
            let bundle = "\(paths.userApplications)/\(name)"
            guard let id = AppBundle.bundleID(of: bundle, files: files), id.hasPrefix(WebApp.bundleIDPrefix),
                !listed.contains(id)
            else { continue }
            do {
                try files.remove(bundle)
                report(.removedWebApp((name as NSString).deletingPathExtension))
            } catch {
                report(.failed(.makeWebApps, error))
                removed = false
            }
        }
        return removed
    }

    /// Runs `work`, giving a file error as a web app error.
    private func onDisk<T>(_ work: () throws(FileSystemError) -> T) throws(WebAppError) -> T {
        do {
            return try work()
        } catch {
            throw .files(error)
        }
    }
}
