/// One setting `[power.battery]` and `[power.charger]` in `macos.toml` take, by a name a person can
/// read, with the name `pmset` gives it.
struct PowerSetting: Sendable {
    /// True or false, which `pmset` keeps as 1 or 0.
    static let flag = CatalogValue.flagAs(on: .integer(1), off: .integer(0))
    /// Minutes, 0 for never.
    static let minutes = CatalogValue.minutes(0...Int.max)

    /// The setting's name in `macos.toml`, such as `dim_screen`.
    let name: String
    /// The name `pmset` gives it, such as `lessbright`.
    let pmset: String
    /// The kind of value it takes.
    let kind: CatalogValue
    /// What the setting does, in a sentence for the docs.
    let about: String

    /// Every power setting `macos.toml` takes, in the order the docs show them.
    static let all = [
        PowerSetting(name: "dim_screen", pmset: "lessbright", kind: flag, about: "Dims the screen a little."),
        PowerSetting(
            name: "dim_before_sleep", pmset: "halfdim", kind: flag,
            about: "Dims the screen before it turns off."),
        PowerSetting(
            name: "screen_off_min", pmset: "displaysleep", kind: minutes,
            about: "Minutes without use before the screen turns off, 0 for never."),
        PowerSetting(
            name: "sleep_min", pmset: "sleep", kind: minutes,
            about: "Minutes without use before the Mac sleeps, 0 for never."),
        PowerSetting(
            name: "disk_sleep_min", pmset: "disksleep", kind: minutes,
            about: "Minutes without use before the disks sleep, 0 for never."),
        PowerSetting(
            name: "wake_for_network", pmset: "womp", kind: flag,
            about: "Wakes the Mac when someone reaches it over the network."),
        PowerSetting(
            name: "power_nap", pmset: "powernap", kind: flag,
            about: "Lets the Mac check for mail and updates while it sleeps."),
        PowerSetting(
            name: "low_power_mode", pmset: "lowpowermode", kind: flag,
            about: "Uses less energy, at the cost of speed."),
    ]

    /// The number `pmset` takes for `value`, or nil when it isn't a value of this setting.
    func pmsetValue(_ value: ConfigValue) -> Int? {
        guard case .set(.integer(let number))? = kind.writes(for: value, targets: 1, home: "")?.first else {
            return nil
        }
        return number
    }

    /// The setting `pmset` calls `name`, or nil when none of them is.
    static func named(pmset name: String) -> PowerSetting? {
        all.first { $0.pmset == name }
    }
}
