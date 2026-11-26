/// The tables about Siri and Game Center.
extension MacOSCatalog {
    /// Siri's own settings.
    private static let siriDomain = "com.apple.Siri"
    /// Whether Siri listens for "Hey Siri".
    private static let listen = CatalogSetting.Target.domain(siriDomain, "VoiceTriggerUserEnabled")
    /// Whether Siri shows in the menu bar.
    private static let menuIcon = CatalogSetting.Target.domain(siriDomain, "StatusMenuVisible")

    /// `[siri]`.
    static let siri = CatalogTable(
        name: "siri", about: "Siri. System Settings, Apple Intelligence & Siri.",
        settings: [
            CatalogSetting(
                "enabled", "Turns Siri on. Off also stops it listening and takes it out of the menu bar.",
                .combinedFlag(
                    on: [.set(.boolean(true)), .leave, .leave],
                    off: [.set(.boolean(false)), .set(.boolean(false)), .set(.boolean(false))]),
                [.domain("com.apple.assistant.support", "Assistant Enabled"), listen, menuIcon]),
            CatalogSetting("listen", "Siri listens for \"Hey Siri\".", .flag, [listen]),
            CatalogSetting("show_in_menu_bar", "Shows Siri in the menu bar.", .flag, [menuIcon]),
        ])

    /// `[game_center]`.
    static let gameCenter = CatalogTable(
        name: "game_center", about: "Game Center. System Settings, Game Center.",
        settings: [
            CatalogSetting(
                "enabled", "Signs in to Game Center.", .invertedFlag,
                [.domain("com.apple.gamed", "GKOptedOutOfGameCenter")])
        ])
}
