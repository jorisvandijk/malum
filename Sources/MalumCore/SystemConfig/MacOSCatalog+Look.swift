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
    static let appearance = MacOSTable(
        name: "appearance", about: "Light or dark, the accent colour and scroll bars. System Settings, Appearance.",
        settings: [
            MacOSSetting(
                "mode", "Light, dark, or switching between them through the day, which macOS does itself.",
                .choice([
                    MacOSChoice("light", [.remove, .remove]),
                    MacOSChoice("dark", [.set(.string("Dark")), .remove]),
                    MacOSChoice("auto", [.leave, .set(.boolean(true))]),
                ]),
                [.global("AppleInterfaceStyle"), .global("AppleInterfaceStyleSwitchesAutomatically")]),
            MacOSSetting(
                "accent_color", "The colour of buttons, selections and highlights.",
                .choice([
                    MacOSChoice("multicolor", [.remove]),
                    .word("graphite", .integer(-1)), .word("red", .integer(0)), .word("orange", .integer(1)),
                    .word("yellow", .integer(2)), .word("green", .integer(3)), .word("blue", .integer(4)),
                    .word("purple", .integer(5)), .word("pink", .integer(6)),
                ]),
                [.global("AppleAccentColor")]),
            MacOSSetting(
                "scroll_bars", "When scroll bars show.",
                .choice([
                    .word("automatic", .string("Automatic")), .word("when_scrolling", .string("WhenScrolling")),
                    .word("always", .string("Always")),
                ]),
                [.global("AppleShowScrollBars")]),
        ])

    /// `[menu_bar]`.
    static let menuBar = MacOSTable(
        name: "menu_bar", about: "When the menu bar hides and which items it shows. System Settings, Menu Bar.",
        settings: [
            MacOSSetting(
                "hide", "When the menu bar hides until the pointer reaches the top of the screen.",
                .choice([
                    MacOSChoice("never", [.set(.boolean(false)), .set(.boolean(true))]),
                    MacOSChoice("in_full_screen", [.set(.boolean(false)), .set(.boolean(false))]),
                    MacOSChoice("on_desktop", [.set(.boolean(true)), .set(.boolean(true))]),
                    MacOSChoice("always", [.set(.boolean(true)), .set(.boolean(false))]),
                ]),
                [.global("_HIHideMenuBar"), .global("AppleMenuBarVisibleInFullscreen")]),
            MacOSSetting(
                "show_spotlight", "Shows the Spotlight icon.", .flagAs(on: .integer(0), off: .integer(1)),
                [.currentHost(Domain.spotlight, "MenuItemHidden")]),
            MacOSSetting(
                "show_now_playing", "Shows Now Playing.", .flagAs(on: menuItemShown, off: menuItemHidden),
                [.currentHost(Domain.controlCenter, "NowPlaying")]),
            MacOSSetting(
                "show_timer", "Shows the timer.", .flagAs(on: menuItemShown, off: menuItemHidden),
                [.currentHost(Domain.controlCenter, "Timer")]),
            MacOSSetting(
                "show_input_menu", "Shows the input menu, to switch keyboard layouts.", .flag,
                [.domain(Domain.inputMenu, "visible")]),
        ])

    /// `[clock]`.
    static let clock = MacOSTable(
        name: "clock", about: "The clock in the menu bar. System Settings, Control Center, Clock Options.",
        settings: [
            MacOSSetting(
                "show_am_pm", "Shows AM or PM after the time.", .flag, [.domain(Domain.clock, "ShowAMPM")]),
            MacOSSetting(
                "show_day_of_week", "Shows the day of the week.", .flag, [.domain(Domain.clock, "ShowDayOfWeek")]),
        ])

    /// `[sound]`.
    static let sound = MacOSTable(
        name: "sound", about: "Alert and interface sounds. System Settings, Sound.",
        settings: [
            MacOSSetting(
                "alert_volume", "How loud the alert sound is, as a percentage of the output volume.", .percent,
                [.global("com.apple.sound.beep.volume")]),
            MacOSSetting(
                "ui_sounds", "Plays sounds for actions such as emptying the Trash.", .flag,
                [.global("com.apple.sound.uiaudio.enabled")]),
        ])
}
// swiftlint:enable no_magic_numbers
