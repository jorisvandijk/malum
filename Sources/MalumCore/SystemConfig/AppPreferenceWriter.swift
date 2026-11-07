import Foundation

/// Sets the preferences apps ask for in their files in `apps/`, or macOS's settings from
/// `macos.toml`, through `defaults`.
///
/// Malum owns each preference it sets: one changed in the app is set back on the next run, and one
/// an app's file doesn't set anymore is removed, so the app falls back to its own default. Other
/// preferences in the domain are left alone.
@MainActor
struct AppPreferenceWriter {
    /// What syncing one domain did.
    private struct Outcome {
        /// The preferences Malum now manages in the domain.
        var keys: [String] = []
        /// Whether all of it worked.
        var succeeded = true
        /// Whether a preference was set or removed.
        var changed = false
    }

    /// Runs `defaults`.
    private let runner: any CommandRunner
    /// Where the record is kept.
    private let state: StateFolder
    /// Whose preferences it sets.
    private let scope: PreferenceScope

    /// Creates the writer of the preferences in `scope`, which runs `defaults` with `runner` and
    /// keeps its record in `state`.
    init(runner: any CommandRunner, state: StateFolder, scope: PreferenceScope = .apps) {
        self.runner = runner
        self.state = state
        self.scope = scope
    }

    /// Sets each preference in `wanted` for its app, and removes each one Malum set that isn't in
    /// it, except those of the apps in `keeping`, telling `changed` each domain it changed. Says
    /// whether everything worked.
    func write(
        _ wanted: [(app: String, preference: AppPreference)], keeping: Set<String>,
        changed: (String) -> Void = { _ in }, report: (Message) -> Void
    ) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: scope.action, report: report) else {
            return false
        }
        var domains: [String: (app: String, wanted: [AppPreference])] = [:]
        for (app, preference) in wanted {
            domains[preference.domain, default: (app, [])].wanted.append(preference)
        }
        let known = scope.managed(in: record)
        for (domain, managed) in known where domains[domain] == nil && !keeping.contains(managed.app) {
            domains[domain] = (managed.app, [])
        }
        var managed = known
        var succeeded = true
        var anyChanged = false
        for (domain, entry) in domains.sorted(by: { $0.key < $1.key }) {
            let source = scope.source(of: entry.app)
            let result = await sync(
                domain, entry.wanted, known: known[domain]?.keys ?? [], source: source, report: report)
            managed[domain] = result.keys.isEmpty ? nil : ManagedPreferences(app: entry.app, keys: result.keys)
            succeeded = succeeded && result.succeeded
            if result.changed {
                anyChanged = true
                changed(domain)
                scope.changed(entry.app).map(report)
            }
        }
        if !wanted.isEmpty && !anyChanged && succeeded {
            report(scope.upToDate)
        }
        guard managed != known else { return succeeded }
        return InstalledRecord.remember(in: state, report: report) { scope.set(managed, in: &$0) } && succeeded
    }

    /// Sets the preferences in `wanted` in `domain`, and removes those in `known` that aren't
    /// wanted anymore.
    private func sync(
        _ domain: String, _ wanted: [AppPreference], known: [String], source: String, report: (Message) -> Void
    ) async -> Outcome {
        let export = await runner.run(Defaults.export(domain))
        guard export.succeeded, let current = Defaults.preferences(in: export.output) else {
            report(.preferencesUnreadable(domain, reason: export.reason))
            return Outcome(keys: known, succeeded: false)
        }
        var outcome = Outcome()
        for preference in wanted {
            guard !Self.same(preference.value, current[preference.key]) else {
                outcome.keys.append(preference.key)
                continue
            }
            let result = await runner.run(Defaults.write(domain, preference.key, preference.value))
            if result.succeeded {
                report(.preferenceSet(preference.key, in: domain, from: source))
                outcome.keys.append(preference.key)
                outcome.changed = true
            } else {
                report(.preferenceNotSet(preference.key, in: domain, reason: result.reason))
                outcome.keys += known.contains(preference.key) ? [preference.key] : []
                outcome.succeeded = false
            }
        }
        let wantedKeys = Set(wanted.map(\.key))
        for key in known where !wantedKeys.contains(key) && current[key] != nil {
            let result = await runner.run(Defaults.delete(domain, key))
            if result.succeeded {
                report(.preferenceRemoved(key, from: domain, source: source))
                outcome.changed = true
            } else {
                report(.preferenceNotRemoved(key, from: domain, reason: result.reason))
                outcome.keys.append(key)
                outcome.succeeded = false
            }
        }
        return outcome
    }

    /// Whether `document`, a property list document, holds the value `current`.
    private static func same(_ document: String, _ current: Any?) -> Bool {
        let data = Data(document.utf8)
        guard let current, let value = try? PropertyListSerialization.propertyList(from: data, format: nil)  // Ours.
        else { return false }
        return NSArray(object: value).isEqual(to: [current])
    }
}
