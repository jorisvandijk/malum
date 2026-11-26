/// Whose preferences an `AppPreferenceWriter` sets, where they come from and where they're recorded.
enum PreferenceScope: Sendable {
    /// The apps' preferences, from their files in `apps/`.
    case apps
    /// macOS's own settings, from `macos.toml`.
    case macOS

    /// The dots file that sets the preferences of `app`.
    func source(of app: String) -> String {
        switch self {
        case .apps:
            Paths.appFile(named: app)
        case .macOS:
            Paths.macOSTOMLName
        }
    }

    /// The preferences of this scope that `record` holds, by domain.
    func managed(in record: InstalledRecord) -> [String: ManagedPreferences] {
        switch self {
        case .apps:
            record.preferences
        case .macOS:
            record.macOS
        }
    }

    /// Puts `managed` in `record` as this scope's preferences.
    func set(_ managed: [String: ManagedPreferences], in record: inout InstalledRecord) {
        switch self {
        case .apps:
            record.preferences = managed
        case .macOS:
            record.macOS = managed
        }
    }

    /// What to say when the preferences of `app` changed, if anything.
    func changed(_ app: String) -> Message? {
        switch self {
        case .apps:
            .reopenToApply(app)
        case .macOS:
            nil
        }
    }

    /// Whether `document`, a property list document, is already held by `current`. macOS's own
    /// settings only need to hold what `macos.toml` asks for, since macOS adds keys to some of them.
    func matches(_ document: String, _ current: Any?) -> Bool {
        PlistMatch.matches(document, current, rule: self == .macOS ? .containing : .exact)
    }

    /// What setting this scope's preferences is called in a message.
    var action: MessageText {
        switch self {
        case .apps:
            .setPreferences
        case .macOS:
            .setMacOSSettings
        }
    }

    /// What to say when every preference already holds what dots says.
    var upToDate: Message {
        switch self {
        case .apps:
            .preferencesUpToDate
        case .macOS:
            .macOSUpToDate
        }
    }
}
