/// One setting a curated table takes, such as `natural_scrolling` in `[pointer]`: the value it
/// takes, what it writes, and what the docs say about it. Each one is a name a person can read for
/// settings only the app's own files or `defaults read` show.
struct CatalogSetting: Sendable {
    /// What a setting does with one of its targets for the value it's given.
    enum Write: Equatable, Sendable {
        /// Sets the target to this value.
        case set(ConfigValue)
        /// Removes the target, which is how macOS stores some choices, such as light mode. A key in
        /// an app's file is left out.
        case remove
        /// Leaves the target as it is.
        case leave
    }

    /// One place a setting writes.
    enum Target: Equatable, Sendable {
        /// A preference, in its domain, with `Defaults.currentHost` for one kept for this Mac only.
        case preference(domain: String, key: String)
        /// A key in one of the app's own files, by its path in the tables the app's `AppConfigFile`
        /// formats read, such as `["settings", "editor.fontSize"]`.
        case file([String])
        /// Keys in one of the app's files, one per item the setting writes, each set to `value`,
        /// in the table at `table`, such as micro's `["bindings"]` with `lua:comment.comment` for
        /// each shortcut of an action.
        case fileKeys(table: [String], value: ConfigValue)
    }

    /// The setting's name in its table, such as `natural_scrolling`.
    let name: String
    /// What the setting does, in a sentence or two for the docs.
    let about: String
    /// The value it takes and how that becomes each target's value.
    let value: CatalogValue
    /// What it writes, in the order `value` gives their values.
    let targets: [Target]

    /// Creates the setting `name`, described by `about`, which takes `value` and writes `targets`.
    init(_ name: String, _ about: String, _ value: CatalogValue, _ targets: [Target]) {
        self.name = name
        self.about = about
        self.value = value
        self.targets = targets
    }

    /// What the setting writes for `given`, one write per target, or nil when `given` isn't a value
    /// it takes. A path in the home folder is filled in with `home`.
    func writes(for given: ConfigValue, home: String) -> [Write]? {
        value.writes(for: given, targets: targets.count, home: home)
    }
}

extension CatalogSetting.Target {
    /// The preference `key` in the global domain, which every app reads.
    static func global(_ key: String) -> Self {
        .preference(domain: globalDomain, key: key)
    }

    /// The preference `key` in `domain`.
    static func domain(_ domain: String, _ key: String) -> Self {
        .preference(domain: domain, key: key)
    }

    /// The preference `key` in the version of `domain` macOS keeps for this Mac only.
    static func currentHost(_ domain: String, _ key: String) -> Self {
        .preference(domain: Defaults.currentHost(domain), key: key)
    }

    /// The domain every app reads, which `defaults` also calls `-g`.
    static let globalDomain = "NSGlobalDomain"
}
