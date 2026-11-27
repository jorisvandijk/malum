/// The tables Malum acts on itself instead of writing preferences: the screen lock, the default
/// apps, Touch ID for sudo, this Mac's name, the screen's size, the power settings, the Apple apps
/// to remove, the hosts file, the apps to open at start and the home folders Finder shows.
extension MacOSCatalog {
    /// `[screen_lock]`.
    static let screenLock = CatalogTable(
        name: ScreenLockSettings.table,
        about: "How soon a black screen asks for your password. System Settings, Lock Screen.",
        settings: [
            CatalogSetting(
                ScreenLockSettings.delayKey,
                "Seconds after the screen goes black, such as when it dims, sleeps or shows the screensaver, "
                    + "before the Mac asks for your password. 0 asks right away.",
                .seconds(0...Int.max), [.own(ScreenLockSettings.table, ScreenLockSettings.delayKey)])
        ])

    /// `[default_apps]`.
    static let defaultApps = CatalogTable(
        name: DefaultApps.table, about: "The apps that open links and files, by bundle ID.",
        settings: DefaultApps.kinds.map { kind in
            CatalogSetting(kind.key, kind.about, .app(before: "", after: ""), [.own(DefaultApps.table, kind.key)])
        })

    /// `[sudo]`.
    static let sudo = CatalogTable(
        name: MacOSSettings.sudoTable, about: "How `sudo` in the terminal asks who you are.",
        settings: [
            CatalogSetting(
                MacOSSettings.touchIDKey, "Lets `sudo` take Touch ID instead of the password.", .flag,
                [.own(MacOSSettings.sudoTable, MacOSSettings.touchIDKey)])
        ])

    /// `[computer]`.
    static let computer = CatalogTable(
        name: ComputerSettings.table, about: "This Mac's name and the sound it makes when it starts up.",
        settings: [
            CatalogSetting(
                ComputerSettings.hostnameKey,
                "All three of the Mac's names, the one people see, the shell's and the local network's: "
                    + "letters, digits and dashes, at most 63, not starting or ending with a dash.",
                .text(.plain), [.own(ComputerSettings.table, ComputerSettings.hostnameKey)]),
            CatalogSetting(
                ComputerSettings.bootSoundKey, "Plays the sound when the Mac starts up.", .flag,
                [.own(ComputerSettings.table, ComputerSettings.bootSoundKey)]),
        ])

    /// `[display]`.
    static let display = CatalogTable(
        name: DisplaySettings.table, about: "The Mac's own screen. System Settings, Displays.",
        settings: [
            CatalogSetting(
                DisplaySettings.resolutionKey,
                "The size the screen shows things at, as width and height in points, such as \"1710x1112\": "
                    + "one of the sizes System Settings offers, from \"Larger Text\" to \"More Space\".",
                .text(.plain), [.own(DisplaySettings.table, DisplaySettings.resolutionKey)])
        ])

    /// `[power]`, which holds a table for each power source.
    static let power = CatalogTable(
        name: PowerSettings.table,
        about: "The power settings, with one table for each power source. Each takes the same settings.",
        settings: [])

    /// `[power.battery]` and `[power.charger]`: the power settings on each power source.
    static let powerSources = Pmset.Source.allCases.map { source in
        CatalogTable(
            name: TableReader.dotted([PowerSettings.table, source.rawValue]),
            about: "The power settings on the \(source.rawValue). System Settings, Battery, Options.",
            settings: PowerSetting.all.map { setting in
                CatalogSetting(
                    setting.name, setting.about, setting.kind,
                    [.own(PowerSettings.table, source.rawValue, setting.pmset)])
            })
    }

    /// `[apple_apps]`.
    static let appleApps = CatalogTable(
        name: AppleApps.table, about: "The Apple apps to remove from `/Applications`.",
        settings: [
            CatalogSetting(
                AppleApps.removeKey,
                "The apps, by name without `.app`, such as \"GarageBand\". Only apps whose bundle ID starts "
                    + "with `com.apple.` are removed.",
                .list(.names), [.own(AppleApps.table, AppleApps.removeKey)])
        ])

    /// `[hosts]`.
    static let hosts = CatalogTable(
        name: MacOSSettings.hostsTable, about: "The names this Mac looks up itself instead of asking DNS.",
        data: CatalogData(
            keys: "a host name, such as \"ha.example.com\"", values: "its address, such as \"10.0.0.110\"",
            into: [MacOSSettings.hostsTable]))

    /// `[startup]`.
    static let startup = CatalogTable(
        name: StartupApps.table, about: "The apps the menu bar app opens each time it starts.",
        settings: [
            CatalogSetting(
                StartupApps.appsKey, "The apps, by bundle ID. One that already runs is left alone.", .list(.apps),
                [.own(StartupApps.table, StartupApps.appsKey)])
        ])

    /// `[home_folders]`.
    static let homeFolders = CatalogTable(
        name: HomeFolders.table, about: "The folders in your home folder that Finder shows.",
        settings: [
            CatalogSetting(
                HomeFolders.showKey,
                "The folders Finder shows, by name, matched without regard to case. Every other one is "
                    + "hidden; ones whose name starts with a dot stay as they are.",
                .list(.names), [.own(HomeFolders.table, HomeFolders.showKey)])
        ])

    /// The tables Malum acts on itself, in the order the docs show them.
    static let systemTables =
        [screenLock, defaultApps, sudo, computer, display, power] + powerSources + [
            appleApps, hosts, startup, homeFolders,
        ]
}
