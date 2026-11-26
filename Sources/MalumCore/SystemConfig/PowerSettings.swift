/// Sets the power settings `[power]` in `macos.toml` lists, by the names in `PowerSetting.all`, as
/// root through the run's one password prompt. The names `pmset` gives them still work for one
/// release, with a warning.
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

    /// The settings in `[power]`, by the name `pmset` gives them, adding a problem to `reader` for
    /// each one that's wrong.
    static func read(_ reader: inout TableReader) -> Wanted {
        let power = reader.table(reader.document, table, at: [])
        reader.unknownKeys(power, at: [table], known: Pmset.Source.allCases.map(\.rawValue))
        var wanted: Wanted = [:]
        for source in Pmset.Source.allCases {
            // The key that set each pmset name first, so a second one that differs is an error.
            var setBy: [String: [String]] = [:]
            for (name, value) in reader.table(power, source.rawValue, at: [table]).sorted(by: { $0.key < $1.key }) {
                let path = [table, source.rawValue, name]
                guard let setting = pmset(name, value, at: path, &reader) else { continue }
                if let earlier = setBy[setting.name], wanted[source]?[setting.name] != setting.number {
                    reader.add(.error, at: path, .setTwice(TableReader.dotted(path), TableReader.dotted(earlier)))
                    continue
                }
                setBy[setting.name] = path
                wanted[source, default: [:]][setting.name] = setting.number
            }
        }
        return wanted
    }

    /// The name `pmset` gives the setting `name` at `path` and the number it takes for `value`, or
    /// nil and a problem in `reader` when the value is wrong. A name `pmset` gives a setting itself
    /// still works, with a warning.
    private static func pmset(
        _ name: String, _ value: ConfigValue, at path: [String], _ reader: inout TableReader
    ) -> (name: String, number: Int)? {
        if let setting = PowerSetting.all.first(where: { $0.name == name }) {
            guard let number = setting.pmsetValue(value) else {
                reader.expect(path, setting.kind)
                return nil
            }
            return (setting.pmset, number)
        }
        let replacement = PowerSetting.named(pmset: name).map { TableReader.dotted(Array(path.dropLast()) + [$0.name]) }
        reader.add(.warn, at: path, .rawPowerSetting(TableReader.dotted(path), replacement))
        guard case .integer(let number) = value else {
            reader.expect(path, SettingKind.integer)
            return nil
        }
        return (name, number)
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
                report(.statusPowerChanged(Self.label(setting), on: name, now: now[setting], set: known.value))
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
            report(.noPowerSetting(Self.label(setting), on: source.rawValue))
            return nil
        }
        if now != value {
            guard await asRoot(Pmset.set(setting, to: value, on: source), setting, source, report) else { return nil }
            report(.powerSet(Self.label(setting), on: source.rawValue, to: value, was: now))
        }
        return now
    }

    /// Sets `setting` on `source`, which is `now`, back to what it was before Malum set it, unless
    /// it was changed outside Malum. Says whether it can be forgotten.
    private func putBack(
        _ setting: String, on source: Pmset.Source, _ known: ManagedPower, now: Int?, _ report: (Message) -> Void
    ) async -> Bool {
        if let now, now != known.value {
            report(.powerKeptChanged(Self.label(setting), on: source.rawValue))
        }
        if now == known.value && known.original != known.value {
            let command = Pmset.set(setting, to: known.original, on: source)
            guard await asRoot(command, setting, source, report) else { return false }
            report(.powerPutBack(Self.label(setting), on: source.rawValue, to: known.original))
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
        if !result.succeeded { report(.powerNotSet(Self.label(setting), on: source.rawValue, reason: result.reason)) }
        return result.succeeded
    }

    /// The name `macos.toml` gives the setting `pmset` calls `setting`, for messages, or `setting`
    /// itself when it has none.
    private static func label(_ setting: String) -> String {
        PowerSetting.named(pmset: setting)?.name ?? setting
    }
}
