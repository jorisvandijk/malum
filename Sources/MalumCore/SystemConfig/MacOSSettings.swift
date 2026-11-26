/// The macOS settings part of system config: sets the preferences the curated tables in
/// `macos.toml` in dots ask for, such as `[trackpad]`, then restarts what has to show them. It also
/// writes the files only root can change (`/etc/hosts` and Touch ID for sudo), sets the power
/// settings, removes the Apple apps it lists, sets the default apps, this Mac's name and boot
/// sound, the size its own screen shows things at, and how soon a black screen asks for the password.
@MainActor
struct MacOSSettings {
    /// The table of preferences by the names macOS stores them under, one table inside it for each
    /// domain. It still works for one release, with a warning: the curated tables replace it.
    static let preferencesTable = "preferences"
    /// The table of preferences macOS keeps for this Mac only, one table inside it for each domain.
    /// Like `[preferences]`, it still works for one release.
    static let currentHostTable = "current_host"
    /// The table of names this Mac looks up itself, each with its address.
    static let hostsTable = "hosts"
    /// The table of how sudo asks who you are.
    static let sudoTable = "sudo"
    /// The key in `[sudo]` that lets sudo take Touch ID.
    static let touchIDKey = "touch_id"

    /// What `macos.toml` sets.
    struct Wanted: Equatable {
        /// The preferences, in every domain.
        var preferences: [AppPreference] = []
        /// The text of each file only root can change, by path.
        var files: [String: String] = [:]
        /// The power settings, by power source and name.
        var power: PowerSettings.Wanted = [:]
        /// The Apple apps to remove.
        var appleApps: [String] = []
        /// The default apps, by key in `[default_apps]`.
        var defaultApps: DefaultApps.Wanted = [:]
        /// This Mac's name and boot sound.
        var computer = ComputerSettings.Wanted()
        /// The size the Mac's own screen shows things at, or nil to leave it.
        var resolution: DisplayResolution?
        /// The seconds after the screen goes black before it asks for the password, or nil to leave it.
        var screenLock: Int?
        /// The folders in the home folder Finder shows, or nil to leave them.
        var homeFolders: [String]?
    }

    /// The process that shows the settings of a domain, which is restarted after a change to it.
    private static let restarts: [String: String] = [
        "com.apple.finder": "Finder",
        "com.apple.desktopservices": "Finder",
        "com.apple.dock": "Dock",
        "com.apple.screencapture": "SystemUIServer",
        "com.apple.menuextra.clock": "ControlCenter",
        Defaults.currentHost("com.apple.controlcenter"): "ControlCenter",
        "com.apple.TextInputMenu": "TextInputMenuAgent",
    ]

    /// The disk.
    private let files: any FileSystem
    /// Runs `defaults` and restarts what shows the settings.
    private let runner: any CommandRunner
    /// Gets root for system-wide settings and the files only root can change.
    private let sudo: SudoSession
    /// Where the record of what Malum set is kept.
    private let state: StateFolder
    /// Where `macos.toml` is.
    private let paths: Paths
    /// Says which app opens what, and changes it.
    private let handlers: any AppHandlers
    /// The Mac's own screen.
    private let display: any Display

    /// Creates the part, which reads `macos.toml` on `files`, sets the settings with `runner`, as
    /// root through `sudo` where needed, keeps its record in `state`, sets the default apps
    /// through `handlers` and the screen's size through `display`.
    init(
        files: any FileSystem, runner: any CommandRunner, sudo: SudoSession, state: StateFolder, paths: Paths,
        handlers: any AppHandlers, display: any Display
    ) {
        self.files = files
        self.runner = runner
        self.sudo = sudo
        self.state = state
        self.paths = paths
        self.handlers = handlers
        self.display = display
    }

    /// Sets the settings in `macos.toml` in the dots folder `dots`, and removes the ones Malum set
    /// that it doesn't list anymore. Leaves every setting alone when there's no such file or it has
    /// errors. Says whether everything worked.
    func run(dots: String, report: (Message) -> Void) async -> Bool {
        let file = paths.macOSTOML(in: dots)
        guard files.item(at: file) != nil else {
            report(.noMacOSSettings(missing: file))
            return true
        }
        let reading: (wanted: Wanted?, problems: [ConfigProblem])
        do {
            reading = Self.read(try files.read(file), home: paths.home)
        } catch {
            report(.failed(.setMacOSSettings, error))
            return false
        }
        reading.problems.map(\.message).forEach(report)
        guard let wanted = reading.wanted else {
            report(.needsFix(.setMacOSSettings, file))
            return false
        }
        let wrote = await SystemFileWriter(runner: runner, files: files, sudo: sudo, state: state).write(
            wanted.files, report: report)
        var changed: Set<String> = []
        let writer = AppPreferenceWriter(runner: runner, files: files, sudo: sudo, state: state, scope: .macOS)
        let preferences = MacOSCatalog.catalog.alwaysPreferences + wanted.preferences
        let set = await writer.write(
            preferences.map { (Paths.macOSTOMLName, $0) }, keeping: [], changed: { changed.insert($0) },
            report: report)
        await show(changed, report: report)
        let power = await PowerSettings(runner: runner, sudo: sudo, state: state).write(wanted.power, report: report)
        let removed = await AppleApps(runner: runner, files: files, sudo: sudo).remove(
            wanted.appleApps, report: report)
        let defaults = await DefaultApps(handlers: handlers).set(wanted.defaultApps, report: report)
        let computer = await ComputerSettings(runner: runner, sudo: sudo).write(wanted.computer, report: report)
        let resolution = DisplaySettings(display: display).set(wanted.resolution, report: report)
        let lock = await ScreenLockSettings(runner: runner, sudo: sudo).set(wanted.screenLock, report: report)
        let folders = await HomeFolders(runner: runner, files: files, paths: paths).set(
            wanted.homeFolders, report: report)
        return wrote && set && power && removed && defaults && computer && resolution && lock && folders
    }

    /// Reads `text`, the contents of `macos.toml`, with a path in the home folder filled in with
    /// `home`: what it sets, or nil when an error stops it, and every problem found.
    static func read(_ text: String, home: String) -> (wanted: Wanted?, problems: [ConfigProblem]) {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.macOSTOMLName)
        } catch {
            return (nil, [error])
        }
        reader.unknownKeys(
            reader.document, at: [],
            known: [
                preferencesTable, currentHostTable, hostsTable, sudoTable, PowerSettings.table, AppleApps.table,
                DefaultApps.table, ComputerSettings.table, DisplaySettings.table, ScreenLockSettings.table,
                StartupApps.table, HomeFolders.table,
            ] + MacOSCatalog.tables.map(\.name))
        var wanted = Wanted()
        let raw =
            domains(preferencesTable, named: { $0 }, &reader)
            + domains(currentHostTable, named: Defaults.currentHost, &reader)
        // The ones Malum always sets come first, so a key that asks for another value is the one
        // that's wrong, and they're left out of what the file sets: `run` adds them.
        let catalog = MacOSCatalog.catalog
        let curated = catalog.read(&reader, home: home).preferences
        wanted.preferences = Array(catalog.merged(curated + raw, &reader).dropFirst(catalog.alwaysPreferences.count))
        if reader.document[hostsTable] != nil {
            wanted.files[SystemFile.hosts.path] = SystemFile.hosts(hosts(&reader))
        }
        if touchID(&reader) {
            wanted.files[SystemFile.sudoLocal.path] = SystemFile.touchID
        }
        wanted.power = PowerSettings.read(&reader)
        wanted.appleApps = AppleApps.read(&reader)
        wanted.defaultApps = DefaultApps.read(&reader)
        wanted.computer = ComputerSettings.read(&reader)
        wanted.resolution = DisplaySettings.read(&reader)
        wanted.screenLock = ScreenLockSettings.read(&reader)
        _ = StartupApps.read(&reader)  // The app opens them when it starts; the run only checks the list.
        wanted.homeFolders = HomeFolders.read(&reader)
        let problems = reader.problemsByLine
        return (reader.hasErrors ? nil : wanted, problems)
    }

    /// The entries of `[hosts]`, each a host name with its address.
    private static func hosts(_ reader: inout TableReader) -> [(key: String, value: String)] {
        let table = reader.table(reader.document, hostsTable, at: [])
        let entries = reader.entries(table, at: [hostsTable], expected: SettingKind.string) {
            guard case .string(let address) = $0 else { return nil }
            return address
        }
        return entries.filter { entry in
            let plain = [entry.key, entry.value].allSatisfy { !$0.isEmpty && !$0.contains { $0.isWhitespace } }
            if !plain {
                reader.add(
                    .error, at: [hostsTable, entry.key], .notHostsEntry(TableReader.dotted([hostsTable, entry.key])))
            }
            return plain
        }
    }

    /// Whether `[sudo]` lets sudo take Touch ID.
    private static func touchID(_ reader: inout TableReader) -> Bool {
        guard let value = reader.onlyKey(touchIDKey, of: sudoTable) else { return false }
        guard case .boolean(let on) = value else {
            reader.expect([sudoTable, touchIDKey], SettingKind.boolean)
            return false
        }
        return on
    }

    /// The preferences in each domain's table inside the table `name`, each in the domain `named`
    /// gives for the table's key, with a warning for each one, since the curated tables replace them.
    private static func domains(
        _ name: String, named domain: (String) -> String, _ reader: inout TableReader
    ) -> [Catalog.Wanted] {
        var preferences: [Catalog.Wanted] = []
        for (key, value) in reader.table(reader.document, name, at: []).sorted(by: { $0.key < $1.key }) {
            let path = [name, key]
            guard !key.hasPrefix("-") else {
                reader.add(.error, at: path, .notDomain(TableReader.dotted(path)))
                continue
            }
            guard let table = reader.table(value, at: path) else { continue }
            let entries = reader.entries(table, at: path, expected: MessageText.plistValue, write: PlistText.document)
            for entry in entries {
                let preference = AppPreference(domain: domain(key), key: entry.key, value: entry.value)
                let entryPath = path + [entry.key]
                let replacement = MacOSCatalog.setting(writing: entry.key, in: preference.domain)
                reader.add(.warn, at: entryPath, .rawPreference(TableReader.dotted(entryPath), replacement))
                preferences.append(Catalog.Wanted(path: entryPath, preference: preference))
            }
        }
        return preferences
    }

    /// Tells running apps that the settings in the domains `changed` changed, and restarts what
    /// shows them. A process that isn't running picks the settings up when it starts.
    private func show(_ changed: Set<String>, report: (Message) -> Void) async {
        guard !changed.isEmpty else { return }
        let activated = await runner.run(ActivateSettings.user)
        if !activated.succeeded { report(.notActivated(reason: activated.reason)) }
        for process in Set(changed.compactMap { Self.restarts[$0] }).sorted() {
            let result = await runner.run(Killall.restart(process))
            guard !Killall.foundNothing(result) else { continue }
            report(result.succeeded ? .restarted(process) : .notRestarted(process, reason: result.reason))
        }
        if changed.contains(where: { Self.restarts[$0] == nil }) {
            report(.logOutToApply)
        }
    }
}
