/// One setting `[power.battery]` and `[power.charger]` in `macos.toml` take, by a name a person can
/// read, with the name `pmset` gives it.
struct PowerSetting: Sendable {
    /// The kind of value a power setting takes.
    enum Kind: Sendable {
        /// True or false, which `pmset` keeps as 1 or 0.
        case flag
        /// Minutes, 0 for never.
        case minutes
    }

    /// The setting's name in `macos.toml`, such as `dim_screen`.
    let name: String
    /// The name `pmset` gives it, such as `lessbright`.
    let pmset: String
    /// The kind of value it takes.
    let kind: Kind
    /// What the setting does, in a sentence for the docs.
    let about: String

    /// Every power setting `macos.toml` takes, in the order the docs show them.
    static let all = [
        PowerSetting(name: "dim_screen", pmset: "lessbright", kind: .flag, about: "Dims the screen a little."),
        PowerSetting(
            name: "dim_before_sleep", pmset: "halfdim", kind: .flag,
            about: "Dims the screen before it turns off."),
        PowerSetting(
            name: "screen_off_min", pmset: "displaysleep", kind: .minutes,
            about: "Minutes without use before the screen turns off, 0 for never."),
        PowerSetting(
            name: "sleep_min", pmset: "sleep", kind: .minutes,
            about: "Minutes without use before the Mac sleeps, 0 for never."),
        PowerSetting(
            name: "disk_sleep_min", pmset: "disksleep", kind: .minutes,
            about: "Minutes without use before the disks sleep, 0 for never."),
        PowerSetting(
            name: "wake_for_network", pmset: "womp", kind: .flag,
            about: "Wakes the Mac when someone reaches it over the network."),
        PowerSetting(
            name: "power_nap", pmset: "powernap", kind: .flag,
            about: "Lets the Mac check for mail and updates while it sleeps."),
        PowerSetting(
            name: "low_power_mode", pmset: "lowpowermode", kind: .flag,
            about: "Uses less energy, at the cost of speed."),
    ]

    /// The number `pmset` takes for `value`, or nil when it isn't a value of this setting.
    func pmsetValue(_ value: ConfigValue) -> Int? {
        switch (kind, value) {
        case (.flag, .boolean(let isOn)):
            isOn ? 1 : 0
        case (.minutes, .integer(let minutes)) where minutes >= 0:
            minutes
        default:
            nil
        }
    }

    /// The setting `pmset` calls `name`, or nil when none of them is.
    static func named(pmset name: String) -> PowerSetting? {
        all.first { $0.pmset == name }
    }
}
