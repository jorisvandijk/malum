/// The catalogs of the apps that keep their settings as macOS preferences only, each setting by a
/// name a person can read for what the app stores in its domain.
enum AppCatalogs {
    /// The preferences domains of these apps.
    enum Domain {
        /// Amphetamine.
        static let amphetamine = "com.if.Amphetamine"
        /// Command X.
        static let commandX = "com.sindresorhus.Command-X"
        /// Cursorcerer.
        static let cursorcerer = "com.doomlaser.cursorcerer"
        /// OverSight.
        static let oversight = "com.objective-see.oversight"
    }

    /// The longest idle time Cursorcerer takes before it hides the pointer, an hour.
    private static let longestIdleSeconds = 3600

    /// `apps/amphetamine.toml`. Malum always keeps the first menu bar icon and sessions that last
    /// until they're ended, which Amphetamine stores as codes.
    static let amphetamine = Catalog(
        file: Paths.appFile(named: "amphetamine"),
        tables: [
            CatalogTable(
                name: "appearance", about: "Where Amphetamine shows. Amphetamine's settings, Appearance.",
                settings: [
                    CatalogSetting(
                        "show_dock_icon", "Whether Amphetamine has an icon in the Dock as well as in the menu bar.",
                        .invertedFlag, [.domain(Domain.amphetamine, "Hide Dock Icon")])
                ]),
            CatalogTable(
                name: "sessions",
                about: "What a session that keeps the Mac awake allows. Amphetamine's settings, Sessions.",
                settings: [
                    CatalogSetting(
                        "allow_display_sleep", "Whether the display may sleep while the Mac stays awake.", .flag,
                        [.domain(Domain.amphetamine, "Allow Display Sleep")]),
                    CatalogSetting(
                        "allow_sleep_when_closed", "Whether a MacBook may sleep when its lid is closed.", .flag,
                        [.domain(Domain.amphetamine, "Allow Closed-Display Sleep")]),
                    CatalogSetting(
                        "allow_screen_saver", "Whether the screen saver may start.", .flag,
                        [.domain(Domain.amphetamine, "Allow Screen Saver")]),
                    CatalogSetting(
                        "move_pointer", "Whether Amphetamine moves the pointer now and then, for apps that watch it.",
                        .flag, [.domain(Domain.amphetamine, "Enable Mouse Movement")]),
                ]),
            CatalogTable(
                name: "statistics", about: "Amphetamine's count of its sessions.",
                settings: [
                    CatalogSetting(
                        "enabled", "Whether Amphetamine keeps statistics of its sessions.", .flag,
                        [.domain(Domain.amphetamine, "Enable Statistics")])
                ]),
        ],
        always: [
            Catalog.Always(target: .domain(Domain.amphetamine, "Icon Style"), value: .integer(0)),
            Catalog.Always(target: .domain(Domain.amphetamine, "Default Duration"), value: .integer(0)),
        ])

    /// `apps/command-x.toml`. Malum always turns on the way of cutting that newer versions use.
    static let commandX = Catalog(
        file: Paths.appFile(named: "command-x"),
        tables: [
            CatalogTable(
                name: "shortcuts", about: "The keys that cut and paste files in Finder.",
                settings: [
                    CatalogSetting(
                        "cut", "Cuts the selected files.", .shortcut(.carbonJSON),
                        [.domain(Domain.commandX, "KeyboardShortcuts_cut")]),
                    CatalogSetting(
                        "paste", "Moves the cut files here.", .shortcut(.carbonJSON),
                        [.domain(Domain.commandX, "KeyboardShortcuts_paste")]),
                ])
        ],
        always: [Catalog.Always(target: .domain(Domain.commandX, "newMethod"), value: .boolean(true))])

    /// `apps/cursorcerer.toml`.
    static let cursorcerer = Catalog(
        file: Paths.appFile(named: "cursorcerer"),
        tables: [
            CatalogTable(
                name: "shortcuts", about: "The key that hides and shows the pointer.",
                settings: [
                    CatalogSetting(
                        "toggle_pointer", "Hides the pointer, or shows it again.",
                        .shortcut(.carbonTable(keyCode: "keyCode", modifiers: "modifiers")),
                        [.domain(Domain.cursorcerer, "toggleCursorHotKey")])
                ]),
            CatalogTable(
                name: "pointer", about: "When Cursorcerer hides the pointer and shows it again.",
                settings: [
                    CatalogSetting(
                        "hide_after_seconds", "How long the pointer stays still before it hides.",
                        .seconds(1...longestIdleSeconds), [.domain(Domain.cursorcerer, "idleHide")]),
                    CatalogSetting(
                        "show_on_move", "Whether a hidden pointer shows again when it moves.", .flag,
                        [.domain(Domain.cursorcerer, "autoShow")]),
                ]),
        ])

    /// `apps/oversight.toml`.
    static let oversight = Catalog(
        file: Paths.appFile(named: "oversight"),
        tables: [
            CatalogTable(
                name: "startup", about: "Whether OverSight opens at login.",
                settings: [
                    CatalogSetting(
                        "at_login", "Whether OverSight opens when you log in.", .flag,
                        [.domain(Domain.oversight, "startAtLogin")])
                ]),
            CatalogTable(
                name: "updates", about: "Whether OverSight checks for new versions.",
                settings: [
                    CatalogSetting(
                        "auto_check", "Whether OverSight checks for a new version when it starts.", .invertedFlag,
                        [.domain(Domain.oversight, "noupdateMode")])
                ]),
        ])
}
