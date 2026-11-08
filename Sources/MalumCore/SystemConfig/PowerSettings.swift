/// Sets the power settings `[power]` in `macos.toml` lists, by the names `pmset` gives them, as
/// root through the run's one password prompt.
///
/// Malum owns each setting it sets: one changed outside Malum is set back on the next run, and one
/// `macos.toml` doesn't set anymore goes back to what it was before Malum first set it, unless it
/// was changed outside Malum: then it stays, and Malum lets it go.
@MainActor
struct PowerSettings {
    /// The table of power settings, one table inside it for each power source.
    static let table = "power"

    /// The settings `macos.toml` sets, by power source and name.
    typealias Wanted = [Pmset.Source: [String: Int]]

    /// Runs `pmset`.
    private let runner: any CommandRunner
    /// Gets root.
    private let sudo: SudoSession
    /// Where the record is kept.
    private let state: StateFolder

    /// Creates the writer, which runs `pmset` with `runner` as root through `sudo` and keeps its
    /// record in `state`.
    init(runner: any CommandRunner, sudo: SudoSession, state: StateFolder) {
        self.runner = runner
        self.sudo = sudo
        self.state = state
    }

    /// The settings in `[power]`, adding a problem to `reader` for each one that's wrong.
    static func read(_ reader: inout TableReader) -> Wanted {
        let power = reader.table(reader.document, table, at: [])
        reader.unknownKeys(power, at: [table], known: Pmset.Source.allCases.map(\.rawValue))
        var wanted: Wanted = [:]
        for source in Pmset.Source.allCases {
            for (setting, value) in reader.table(power, source.rawValue, at: [table]) {
                guard case .integer(let number) = value else {
                    reader.expect([table, source.rawValue, setting], SettingKind.integer)
                    continue
                }
                wanted[source, default: [:]][setting] = number
            }
        }
        return wanted
    }

    /// Makes each setting in `wanted` hold its value, and puts back each one Malum set that isn't
    /// in it. Says whether everything worked.
    func write(_ wanted: Wanted, report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: .setMacOSSettings, report: report) else {
            return false
        }
        guard !wanted.isEmpty || !record.power.isEmpty else { return true }
        let read = await runner.run(Pmset.custom)
        guard read.succeeded else {
            report(.powerUnreadable(reason: read.reason))
            return false
        }
        let current = Pmset.settings(in: read.output)
        var managed = record.power
        let set = await setAll(wanted, current: current, &managed, report)
        let putBack = await putBackDropped(wanted, current: current, &managed, report)
        guard managed != record.power else { return set && putBack }
        return InstalledRecord.remember(in: state, report: report) { $0.power = managed } && set && putBack
    }

    /// Reports how the settings in `managed` look now, changing nothing: each one that holds
    /// something else than Malum set. Says whether it could tell.
    func status(_ managed: [String: [String: ManagedPower]], report: (Message) -> Void) async -> Bool {
        guard !managed.isEmpty else { return true }
        let read = await runner.run(Pmset.custom)
        guard read.succeeded else {
            report(.powerUnreadable(reason: read.reason))
            return false
        }
        let current = Pmset.settings(in: read.output)
        report(.statusManaged(managed.values.map(\.count).reduce(0, +), .powerSettings))
        for (name, settings) in managed.sorted(by: { $0.key < $1.key }) {
            let now = Pmset.Source(rawValue: name).flatMap { current[$0] } ?? [:]
            for (setting, known) in settings.sorted(by: { $0.key < $1.key }) where now[setting] != known.value {
                report(.statusPowerChanged(setting, on: name, now: now[setting], set: known.value))
            }
        }
        return true
    }

    /// Sets each setting in `wanted`, where `current` holds what they are now, and records it in
    /// `managed`. Says whether everything worked.
    private func setAll(
        _ wanted: Wanted, current: Wanted, _ managed: inout [String: [String: ManagedPower]],
        _ report: (Message) -> Void
    ) async -> Bool {
        var succeeded = true
        for (source, settings) in wanted.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard let now = current[source] else {
                report(.noPowerSource(source.rawValue))
                continue
            }
            for (setting, value) in settings.sorted(by: { $0.key < $1.key }) {
                guard let was = await set(setting, to: value, on: source, now: now[setting], report) else {
                    succeeded = false
                    continue
                }
                let original = managed[source.rawValue]?[setting]?.original ?? was
                managed[source.rawValue, default: [:]][setting] = ManagedPower(value: value, original: original)
            }
        }
        return succeeded
    }

    /// Puts back each setting in `managed` that isn't in `wanted`, where `current` holds what they
    /// are now, and forgets it. Says whether everything worked.
    private func putBackDropped(
        _ wanted: Wanted, current: Wanted, _ managed: inout [String: [String: ManagedPower]],
        _ report: (Message) -> Void
    ) async -> Bool {
        var succeeded = true
        for (name, settings) in managed.sorted(by: { $0.key < $1.key }) {
            guard let source = Pmset.Source(rawValue: name) else { continue }
            for (setting, known) in settings.sorted(by: { $0.key < $1.key }) where wanted[source]?[setting] == nil {
                guard await putBack(setting, on: source, known, now: current[source]?[setting], report) else {
                    succeeded = false
                    continue
                }
                managed[name]?[setting] = nil
                if managed[name]?.isEmpty == true { managed[name] = nil }
            }
        }
        return succeeded
    }

    /// Sets `setting` on `source`, which is `now`, to `value` when it isn't yet. Gives what it was,
    /// or nil when it failed.
    private func set(
        _ setting: String, to value: Int, on source: Pmset.Source, now: Int?, _ report: (Message) -> Void
    ) async -> Int? {
        guard let now else {
            report(.noPowerSetting(setting, on: source.rawValue))
            return nil
        }
        if now != value {
            guard await asRoot(Pmset.set(setting, to: value, on: source), setting, source, report) else { return nil }
            report(.powerSet(setting, on: source.rawValue, to: value, was: now))
        }
        return now
    }

    /// Sets `setting` on `source`, which is `now`, back to what it was before Malum set it, unless
    /// it was changed outside Malum. Says whether it can be forgotten.
    private func putBack(
        _ setting: String, on source: Pmset.Source, _ known: ManagedPower, now: Int?, _ report: (Message) -> Void
    ) async -> Bool {
        if let now, now != known.value {
            report(.powerKeptChanged(setting, on: source.rawValue))
        }
        if now == known.value && known.original != known.value {
            let command = Pmset.set(setting, to: known.original, on: source)
            guard await asRoot(command, setting, source, report) else { return false }
            report(.powerPutBack(setting, on: source.rawValue, to: known.original))
        }
        return true
    }

    /// Runs `command`, which changes `setting` on `source`, as root, asking for the password the
    /// first time. Says whether it worked.
    private func asRoot(
        _ command: Command, _ setting: String, _ source: Pmset.Source, _ report: (Message) -> Void
    ) async -> Bool {
        guard await sudo.authorize(for: .changePower, report: report) else { return false }
        let result = await runner.run(Sudo.asRoot(command))
        if !result.succeeded { report(.powerNotSet(setting, on: source.rawValue, reason: result.reason)) }
        return result.succeeded
    }
}
