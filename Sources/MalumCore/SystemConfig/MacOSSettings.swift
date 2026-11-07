/// The macOS settings part of system config: sets the preferences `macos.toml` in dots lists, by
/// domain and the names macOS stores them under, then restarts what has to show them.
@MainActor
struct MacOSSettings {
    /// The table of preferences, one table inside it for each domain.
    static let preferencesTable = "preferences"
    /// The table of preferences macOS keeps for this Mac only, one table inside it for each domain.
    static let currentHostTable = "current_host"

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
    /// Where the record of what Malum set is kept.
    private let state: StateFolder
    /// Where `macos.toml` is.
    private let paths: Paths

    /// Creates the part, which reads `macos.toml` on `files`, sets the settings with `runner`, and
    /// keeps its record in `state`.
    init(files: any FileSystem, runner: any CommandRunner, state: StateFolder, paths: Paths) {
        self.files = files
        self.runner = runner
        self.state = state
        self.paths = paths
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
        let reading: (preferences: [AppPreference]?, problems: [ConfigProblem])
        do {
            reading = Self.read(try files.read(file))
        } catch {
            report(.failed(.setMacOSSettings, error))
            return false
        }
        reading.problems.map(\.message).forEach(report)
        guard let preferences = reading.preferences else {
            report(.needsFix(.setMacOSSettings, file))
            return false
        }
        var changed: Set<String> = []
        let writer = AppPreferenceWriter(runner: runner, state: state, scope: .macOS)
        let succeeded = await writer.write(
            preferences.map { (Paths.macOSTOMLName, $0) }, keeping: [], changed: { changed.insert($0) }, report: report)
        await show(changed, report: report)
        return succeeded
    }

    /// Reads `text`, the contents of `macos.toml`: its preferences, or nil when an error stops
    /// them, and every problem found.
    static func read(_ text: String) -> (preferences: [AppPreference]?, problems: [ConfigProblem]) {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.macOSTOMLName)
        } catch {
            return (nil, [error])
        }
        reader.unknownKeys(reader.document, at: [], known: [preferencesTable, currentHostTable])
        let preferences =
            domains(preferencesTable, named: { $0 }, &reader)
            + domains(currentHostTable, named: Defaults.currentHost, &reader)
        let problems = reader.problems.sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
        return (reader.hasErrors ? nil : preferences, problems)
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
