/// One setting a curated table in `macos.toml` takes, such as `natural_scrolling` in `[pointer]`:
/// the value it takes, the preferences it writes, and what the docs say about it. Each one is a
/// name a person can read for macOS preferences only `defaults read` shows.
struct MacOSSetting: Sendable {
    /// What a setting does with one of its preferences for the value it's given.
    enum Write: Equatable, Sendable {
        /// Sets the preference to this value.
        case set(ConfigValue)
        /// Removes the preference, which is how macOS stores some choices, such as light mode.
        case remove
        /// Leaves the preference as it is.
        case leave
    }

    /// One preference a setting writes.
    struct Target: Equatable, Sendable {
        /// The preferences domain, with `Defaults.currentHost` for one kept for this Mac only.
        let domain: String
        /// The preference's name, as macOS stores it.
        let key: String
    }

    /// The setting's name in its table, such as `natural_scrolling`.
    let name: String
    /// What the setting does, in a sentence or two for the docs.
    let about: String
    /// The value it takes and how that becomes each preference's value.
    let value: MacOSValue
    /// The preferences it writes, in the order `value` gives their values.
    let targets: [Target]

    /// Creates the setting `name`, described by `about`, which takes `value` and writes `targets`.
    init(_ name: String, _ about: String, _ value: MacOSValue, _ targets: [Target]) {
        self.name = name
        self.about = about
        self.value = value
        self.targets = targets
    }

    /// What the setting writes for `given`, one write per target, or nil when `given` isn't a value
    /// it takes.
    func writes(for given: ConfigValue) -> [Write]? {
        value.writes(for: given, targets: targets.count)
    }
}

extension MacOSSetting.Target {
    /// The preference `key` in the global domain, which every app reads.
    static func global(_ key: String) -> Self {
        Self(domain: globalDomain, key: key)
    }

    /// The preference `key` in `domain`.
    static func domain(_ domain: String, _ key: String) -> Self {
        Self(domain: domain, key: key)
    }

    /// The preference `key` in the version of `domain` macOS keeps for this Mac only.
    static func currentHost(_ domain: String, _ key: String) -> Self {
        Self(domain: Defaults.currentHost(domain), key: key)
    }

    /// The domain every app reads, which `defaults` also calls `-g`.
    static let globalDomain = "NSGlobalDomain"
}
