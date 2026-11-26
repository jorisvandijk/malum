/// The tables about Siri and Game Center.
extension MacOSCatalog {
    /// Siri's own settings.
    private static let siriDomain = "com.apple.Siri"
    /// Whether Siri listens for "Hey Siri".
    private static let listen = MacOSSetting.Target.domain(siriDomain, "VoiceTriggerUserEnabled")
    /// Whether Siri shows in the menu bar.
    private static let menuIcon = MacOSSetting.Target.domain(siriDomain, "StatusMenuVisible")

    /// `[siri]`.
    static let siri = MacOSTable(
        name: "siri", about: "Siri. System Settings, Apple Intelligence & Siri.",
        settings: [
            MacOSSetting(
                "enabled", "Turns Siri on. Off also stops it listening and takes it out of the menu bar.",
                .combinedFlag(
                    on: [.set(.boolean(true)), .leave, .leave],
                    off: [.set(.boolean(false)), .set(.boolean(false)), .set(.boolean(false))]),
                [.domain("com.apple.assistant.support", "Assistant Enabled"), listen, menuIcon]),
            MacOSSetting("listen", "Siri listens for \"Hey Siri\".", .flag, [listen]),
            MacOSSetting("show_in_menu_bar", "Shows Siri in the menu bar.", .flag, [menuIcon]),
        ])

    /// `[game_center]`.
    static let gameCenter = MacOSTable(
        name: "game_center", about: "Game Center. System Settings, Game Center.",
        settings: [
            MacOSSetting(
                "enabled", "Signs in to Game Center.", .invertedFlag,
                [.domain("com.apple.gamed", "GKOptedOutOfGameCenter")])
        ])
}
