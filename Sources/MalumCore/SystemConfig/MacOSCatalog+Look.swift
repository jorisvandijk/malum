// swiftlint:disable no_magic_numbers
// Lookup tables: each row names the values macOS stores a choice as.

/// The tables about how macOS looks and sounds.
extension MacOSCatalog {
    /// The domains these tables write to, besides the global one.
    private enum Domain {
        /// Menu bar items kept for this Mac only.
        static let controlCenter = "com.apple.controlcenter"
        /// The menu bar's clock.
        static let clock = "com.apple.menuextra.clock"
        /// Spotlight.
        static let spotlight = "com.apple.Spotlight"
        /// The input menu in the menu bar.
        static let inputMenu = "com.apple.TextInputMenu"
    }

    /// How ControlCenter stores a menu bar item that shows.
    private static let menuItemShown = ConfigValue.integer(18)
    /// How ControlCenter stores a menu bar item that's hidden.
    private static let menuItemHidden = ConfigValue.integer(8)

    /// `[appearance]`.
    static let appearance = CatalogTable(
        name: "appearance", about: "Light or dark, the accent colour and scroll bars. System Settings, Appearance.",
        settings: [
            CatalogSetting(
                "mode", "Light, dark, or switching between them through the day, which macOS does itself.",
                .choice([
                    CatalogChoice("light", [.remove, .remove]),
                    CatalogChoice("dark", [.set(.string("Dark")), .remove]),
                    CatalogChoice("auto", [.leave, .set(.boolean(true))]),
                ]),
                [.global("AppleInterfaceStyle"), .global("AppleInterfaceStyleSwitchesAutomatically")]),
            CatalogSetting(
                "accent_color", "The colour of buttons, selections and highlights.",
                .choice([
                    CatalogChoice("multicolor", [.remove]),
                    .word("graphite", .integer(-1)), .word("red", .integer(0)), .word("orange", .integer(1)),
                    .word("yellow", .integer(2)), .word("green", .integer(3)), .word("blue", .integer(4)),
                    .word("purple", .integer(5)), .word("pink", .integer(6)),
                ]),
                [.global("AppleAccentColor")]),
            CatalogSetting(
                "scroll_bars", "When scroll bars show.",
                .choice([
                    .word("automatic", .string("Automatic")), .word("when_scrolling", .string("WhenScrolling")),
                    .word("always", .string("Always")),
                ]),
                [.global("AppleShowScrollBars")]),
        ])

    /// `[menu_bar]`.
    static let menuBar = CatalogTable(
        name: "menu_bar", about: "When the menu bar shows and which items it shows. System Settings, Menu Bar.",
        settings: [
            CatalogSetting(
                "show",
                "When the menu bar shows; the rest of the time it hides until the pointer reaches the top "
                    + "of the screen.",
                .choice([
                    CatalogChoice("always", [.set(.boolean(false)), .set(.boolean(true))]),
                    CatalogChoice("outside_full_screen", [.set(.boolean(false)), .set(.boolean(false))]),
                    CatalogChoice("in_full_screen", [.set(.boolean(true)), .set(.boolean(true))]),
                    CatalogChoice("never", [.set(.boolean(true)), .set(.boolean(false))]),
                ]),
                [.global("_HIHideMenuBar"), .global("AppleMenuBarVisibleInFullscreen")]),
            CatalogSetting(
                "show_spotlight", "Shows the Spotlight icon.", .flagAs(on: .integer(0), off: .integer(1)),
                [.currentHost(Domain.spotlight, "MenuItemHidden")]),
            CatalogSetting(
                "show_now_playing", "Shows Now Playing.", .flagAs(on: menuItemShown, off: menuItemHidden),
                [.currentHost(Domain.controlCenter, "NowPlaying")]),
            CatalogSetting(
                "show_timer", "Shows the timer.", .flagAs(on: menuItemShown, off: menuItemHidden),
                [.currentHost(Domain.controlCenter, "Timer")]),
            CatalogSetting(
                "show_input_menu", "Shows the input menu, to switch keyboard layouts.", .flag,
                [.domain(Domain.inputMenu, "visible")]),
        ])

    /// `[clock]`.
    static let clock = CatalogTable(
        name: "clock", about: "The clock in the menu bar. System Settings, Control Center, Clock Options.",
        settings: [
            CatalogSetting(
                "show_am_pm", "Shows AM or PM after the time.", .flag, [.domain(Domain.clock, "ShowAMPM")]),
            CatalogSetting(
                "show_day_of_week", "Shows the day of the week.", .flag, [.domain(Domain.clock, "ShowDayOfWeek")]),
        ])

    /// `[sound]`.
    static let sound = CatalogTable(
        name: "sound", about: "Alert and interface sounds. System Settings, Sound.",
        settings: [
            CatalogSetting(
                "alert_volume_percent", "How loud the alert sound is, as a percentage of the output volume.", .percent,
                [.global("com.apple.sound.beep.volume")]),
            CatalogSetting(
                "ui_sounds", "Plays sounds for actions such as emptying the Trash.", .flag,
                [.global("com.apple.sound.uiaudio.enabled")]),
        ])
}
// swiftlint:enable no_magic_numbers
