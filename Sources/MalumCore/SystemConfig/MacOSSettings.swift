/// The macOS settings part of system config: sets the preferences the curated tables in
/// `macos.toml` in dots ask for, such as `[trackpad]`, then restarts what has to show them. It also
/// writes the files only root can change (`/etc/hosts` and Touch ID for sudo), sets the power
/// settings, removes the Apple apps it lists, sets the default apps, this Mac's name and boot
/// sound, the size its own screen shows things at, and how soon a black screen asks for the password.
@MainActor
struct MacOSSettings {
    /// The table of names this Mac looks up itself, each with its address.
    nonisolated static let hostsTable = "hosts"
    /// The table of how sudo asks who you are.
    nonisolated static let sudoTable = "sudo"
    /// The key in `[sudo]` that lets sudo take Touch ID.
    nonisolated static let touchIDKey = "touch_id"

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
        let catalog = MacOSCatalog.catalog
        reader.unknownKeys(reader.document, at: [], known: catalog.topTables)
        // The ones Malum always sets come first, so a key that asks for another value is the one
        // that's wrong, and they're left out of what the file sets: `run` adds them.
        let reading = catalog.read(&reader, home: home)
        let own = catalog.tables(reading.files, &reader)
        var wanted = Wanted()
        wanted.preferences = Array(
            catalog.merged(reading.preferences, &reader).dropFirst(catalog.alwaysPreferences.count))
        if reader.document[hostsTable] != nil {
            wanted.files[SystemFile.hosts.path] = SystemFile.hosts(hosts(own, &reader))
        }
        if own.value(at: [sudoTable, touchIDKey]) == .boolean(true) {
            wanted.files[SystemFile.sudoLocal.path] = SystemFile.touchID
        }
        wanted.power = PowerSettings.read(own)
        wanted.appleApps = AppleApps.read(own)
        wanted.defaultApps = DefaultApps.read(own)
        wanted.computer = ComputerSettings.read(own, &reader)
        wanted.resolution = DisplaySettings.read(own, &reader)
        wanted.screenLock = ScreenLockSettings.read(own)
        wanted.homeFolders = HomeFolders.read(own)
        // The app opens `[startup] apps` when it starts; the run only checks the list.
        let problems = reader.problemsByLine
        return (reader.hasErrors ? nil : wanted, problems)
    }

    /// The entries of `[hosts]` in `own`, the tables the catalog read from `macos.toml`, each a host
    /// name with its address, adding a problem to `reader` for each one that's wrong.
    private static func hosts(_ own: ConfigTable, _ reader: inout TableReader) -> [(key: String, value: String)] {
        let table = reader.table(own, hostsTable, at: [])
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
