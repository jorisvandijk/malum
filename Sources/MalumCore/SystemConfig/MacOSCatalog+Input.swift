/// The tables about the pointer, the trackpad, the keyboard and typing.
extension MacOSCatalog {
    /// The two domains macOS keeps the trackpad's settings in: the built-in one and the Magic Trackpad.
    private static let trackpads = [
        "com.apple.AppleMultitouchTrackpad", "com.apple.driver.AppleBluetoothMultitouch.trackpad",
    ]
    /// How long one step of key repeat is, in milliseconds.
    private static let repeatStep = 15
    /// The key repeat times System Settings' sliders reach, in milliseconds.
    private static let repeatRange = 15...1800

    /// `[pointer]`.
    static let pointer = CatalogTable(
        name: "pointer", about: "What the mouse and the trackpad share. System Settings, Mouse and Trackpad.",
        settings: [
            CatalogSetting(
                "natural_scrolling", "Content follows your fingers, as on a phone. macOS sets it for the mouse too.",
                .flag, [.global("com.apple.swipescrolldirection")]),
            CatalogSetting(
                "shake_to_locate", "Makes the pointer bigger for a moment when you shake it.", .invertedFlag,
                [.global("CGDisableCursorLocationMagnification")]),
        ])

    /// `[trackpad]`.
    static let trackpad = CatalogTable(
        name: "trackpad", about: "The built-in trackpad and the Magic Trackpad. System Settings, Trackpad.",
        settings: [
            CatalogSetting(
                "tap_to_click", "A tap clicks, without pressing the trackpad down.", .flag,
                trackpads.map { CatalogSetting.Target.domain($0, "Clicking") }),
            CatalogSetting(
                "three_finger_drag", "Drags windows and selections with three fingers. Accessibility, Pointer Control.",
                .flag, trackpads.map { CatalogSetting.Target.domain($0, "TrackpadThreeFingerDrag") }),
            CatalogSetting(
                "force_click", "A harder press looks things up or previews them.", .flag,
                [.global("com.apple.trackpad.forceClick")]),
        ])

    /// `[keyboard]`.
    static let keyboard = CatalogTable(
        name: "keyboard", about: "Key repeat, the backlight and the keyboard layouts. System Settings, Keyboard.",
        settings: [
            CatalogSetting(
                "repeat_delay_ms", "How long a key is held before it starts repeating, in milliseconds.",
                .milliseconds(step: repeatStep, range: repeatRange), [.global("InitialKeyRepeat")]),
            CatalogSetting(
                "repeat_interval_ms", "The time between repeats of a held key, in milliseconds.",
                .milliseconds(step: repeatStep, range: repeatRange), [.global("KeyRepeat")]),
            CatalogSetting(
                "auto_backlight", "Turns the keyboard's backlight on in low light.", .flag,
                [.domain("com.apple.BezelServices", "dAuto")]),
            CatalogSetting(
                "input_sources", "The keyboard layouts you switch between, the first one in use.",
                .list(.keyboardLayouts), [.domain("com.apple.HIToolbox", "AppleEnabledInputSources")]),
        ])

    /// `[text]`.
    static let text = CatalogTable(
        name: "text", about: "What macOS changes as you type. System Settings, Keyboard, Text Input.",
        settings: [
            CatalogSetting(
                "auto_correct", "Corrects spelling as you type, in apps and on web pages.", .flag,
                [.global("NSAutomaticSpellingCorrectionEnabled"), .global("WebAutomaticSpellingCorrectionEnabled")]),
            CatalogSetting(
                "auto_capitalize", "Starts sentences with a capital.", .flag,
                [.global("NSAutomaticCapitalizationEnabled")]),
            CatalogSetting(
                "auto_period", "Two spaces type a period.", .flag, [.global("NSAutomaticPeriodSubstitutionEnabled")]),
            CatalogSetting(
                "smart_dashes", "Two hyphens become a dash.", .flag, [.global("NSAutomaticDashSubstitutionEnabled")]),
            CatalogSetting(
                "smart_quotes", "Straight quotes become curly ones.", .flag,
                [.global("NSAutomaticQuoteSubstitutionEnabled")]),
        ])
}
