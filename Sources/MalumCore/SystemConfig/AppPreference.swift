/// A preference of an app, set by system config from the app's file in dots, or one of macOS's
/// own settings from `macos.toml`.
public struct AppPreference: Equatable, Sendable {
    /// The preferences domain, such as `com.if.Amphetamine`.
    public let domain: String
    /// The preference's name, as the app stores it.
    public let key: String
    /// The value, as a property list document, or nil when the preference has to be absent, the
    /// way macOS stores some choices, such as light mode.
    public let value: String?
    /// The name `macos.toml` gives the setting, such as `pointer.natural_scrolling`, for messages,
    /// or nil when the file names the preference itself.
    public let setting: String?

    /// Creates the preference `key` in `domain`, which holds `value`, or has to be absent when it's
    /// nil, set from the setting `setting` in `macos.toml` when there's one.
    public init(domain: String, key: String, value: String?, setting: String? = nil) {
        self.domain = domain
        self.key = key
        self.value = value
        self.setting = setting
    }
}
