/// The macOS settings part of system config: sets the preferences `macos.toml` in dots lists, by
/// domain and the names macOS stores them under, then restarts what has to show them. It also
/// writes the files only root can change (`/etc/hosts` and Touch ID for sudo), sets the power
/// settings, removes the Apple apps it lists and sets the default apps.
@MainActor
struct MacOSSettings {
    /// The table of preferences, one table inside it for each domain.
    static let preferencesTable = "preferences"
    /// The table of preferences macOS keeps for this Mac only, one table inside it for each domain.
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

    /// Creates the part, which reads `macos.toml` on `files`, sets the settings with `runner`, as
    /// root through `sudo` where needed, keeps its record in `state` and sets the default apps
    /// through `handlers`.
    init(
        files: any FileSystem, runner: any CommandRunner, sudo: SudoSession, state: StateFolder, paths: Paths,
        handlers: any AppHandlers
    ) {
        self.files = files
        self.runner = runner
        self.sudo = sudo
        self.state = state
        self.paths = paths
        self.handlers = handlers
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
            reading = Self.read(try files.read(file))
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
        let set = await writer.write(
            wanted.preferences.map { (Paths.macOSTOMLName, $0) }, keeping: [], changed: { changed.insert($0) },
            report: report)
        await show(changed, report: report)
        let power = await PowerSettings(runner: runner, sudo: sudo, state: state).write(wanted.power, report: report)
        let removed = await AppleApps(runner: runner, files: files, sudo: sudo).remove(
            wanted.appleApps, report: report)
        let defaults = await DefaultApps(handlers: handlers).set(wanted.defaultApps, report: report)
        return wrote && set && power && removed && defaults
    }

    /// Reads `text`, the contents of `macos.toml`: what it sets, or nil when an error stops it, and
    /// every problem found.
    static func read(_ text: String) -> (wanted: Wanted?, problems: [ConfigProblem]) {
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
                DefaultApps.table,
            ])
        var wanted = Wanted()
        wanted.preferences =
            domains(preferencesTable, named: { $0 }, &reader)
            + domains(currentHostTable, named: Defaults.currentHost, &reader)
        if reader.document[hostsTable] != nil {
            wanted.files[SystemFile.hosts.path] = SystemFile.hosts(hosts(&reader))
        }
        if touchID(&reader) {
            wanted.files[SystemFile.sudoLocal.path] = SystemFile.touchID
        }
        wanted.power = PowerSettings.read(&reader)
        wanted.appleApps = AppleApps.read(&reader)
        wanted.defaultApps = DefaultApps.read(&reader)
        let problems = reader.problems.sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
        return (reader.hasErrors ? nil : wanted, problems)
    }

    /// The entries of `[hosts]`, each a host name with its address.
    private static func hosts(_ reader: inout TableReader) -> [(key: String, value: String)] {
        let table = reader.table(reader.document, hostsTable, at: [])
        let entries = reader.entries(table, at: [hostsTable], expected: SettingKind.string.description) {
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
        guard reader.document[sudoTable] != nil else { return false }
        let table = reader.table(reader.document, sudoTable, at: [])
        reader.unknownKeys(table, at: [sudoTable], known: [touchIDKey])
        guard let value = table[touchIDKey] else { return false }
        guard case .boolean(let on) = value else {
            reader.expect([sudoTable, touchIDKey], SettingKind.boolean)
            return false
        }
        return on
    }

    /// The preferences in each domain's table inside the table `name`, each in the domain `named`
    /// gives for the table's key.
    private static func domains(
        _ name: String, named domain: (String) -> String, _ reader: inout TableReader
    ) -> [AppPreference] {
        var preferences: [AppPreference] = []
        for (key, value) in reader.table(reader.document, name, at: []).sorted(by: { $0.key < $1.key }) {
            let path = [name, key]
            guard !key.hasPrefix("-") else {
                reader.add(.error, at: path, .notDomain(TableReader.dotted(path)))
                continue
            }
            guard let table = reader.table(value, at: path) else { continue }
            let entries = reader.entries(table, at: path, expected: PlistText.expected, write: PlistText.document)
            preferences += entries.map { AppPreference(domain: domain(key), key: $0.key, value: $0.value) }
        }
        return preferences
    }

    /// Tells running apps that the settings in the domains `changed` changed, and restarts what
    /// shows them.
    private func show(_ changed: Set<String>, report: (Message) -> Void) async {
        guard !changed.isEmpty else { return }
        let activated = await runner.run(ActivateSettings.user)
        if !activated.succeeded { report(.notActivated(reason: activated.reason)) }
        for process in Set(changed.compactMap { Self.restarts[$0] }).sorted() {
            let result = await runner.run(Killall.restart(process))
            report(result.succeeded ? .restarted(process) : .notRestarted(process, reason: result.reason))
        }
        if changed.contains(where: { Self.restarts[$0] == nil }) {
            report(.logOutToApply)
        }
    }
}
