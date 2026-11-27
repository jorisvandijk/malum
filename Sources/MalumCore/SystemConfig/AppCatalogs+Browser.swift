/// The catalog of LibreWolf, whose settings go into its profile's `user.js` and whose add-ons,
/// bookmarks and search engines go into its policies, which every user of the Mac gets.
extension AppCatalogs {
    /// A preference in LibreWolf's `user.js`, by its name in `about:config`.
    private static func libreWolf(_ key: String) -> CatalogSetting.Target {
        .file([LibreWolfPolicies.settingsTable, key])
    }

    /// A key in LibreWolf's policies, by its path in Mozilla's policy templates.
    private static func policy(_ path: String...) -> CatalogSetting.Target {
        .file([AppConfig.policiesTable] + path)
    }

    /// The languages LibreWolf's translations know, by their names and the codes LibreWolf keeps.
    private static let languages = [
        ("arabic", "ar"), ("bulgarian", "bg"), ("catalan", "ca"), ("chinese", "zh"), ("croatian", "hr"),
        ("czech", "cs"), ("danish", "da"), ("dutch", "nl"), ("english", "en"), ("estonian", "et"),
        ("finnish", "fi"), ("french", "fr"), ("german", "de"), ("greek", "el"), ("hindi", "hi"),
        ("hungarian", "hu"), ("indonesian", "id"), ("italian", "it"), ("japanese", "ja"), ("korean", "ko"),
        ("latvian", "lv"), ("lithuanian", "lt"), ("persian", "fa"), ("polish", "pl"), ("portuguese", "pt"),
        ("romanian", "ro"), ("russian", "ru"), ("serbian", "sr"), ("slovak", "sk"), ("slovenian", "sl"),
        ("spanish", "es"), ("swedish", "sv"), ("turkish", "tr"), ("ukrainian", "uk"), ("vietnamese", "vi"),
    ].map { CatalogValue.Part($0.0, $0.1) }

    /// The tools LibreWolf's sidebar can show, by their names and the ids LibreWolf keeps.
    private static let sidebarTools = [
        CatalogValue.Part("chatbot", "aichat"), CatalogValue.Part("synced_tabs", "syncedtabs"),
        CatalogValue.Part("history", "history"), CatalogValue.Part("bookmarks", "bookmarks"),
    ]

    /// The buttons LibreWolf's toolbar takes, by their names and the ids LibreWolf keeps.
    private static let toolbarButtons = [
        ("back", "back-button"), ("forward", "forward-button"), ("reload", "stop-reload-button"),
        ("home", "home-button"), ("space", "spring"), ("address_bar", "urlbar-container"),
        ("downloads", "downloads-button"), ("library", "library-button"), ("sidebar", "sidebar-button"),
        ("bookmarks", "bookmarks-menu-button"), ("history", "history-panelmenu"), ("new_tab", "new-tab-button"),
        ("new_window", "new-window-button"), ("print", "print-button"), ("fullscreen", "fullscreen-button"),
        ("developer", "developer-button"), ("account", "fxa-toolbar-menu-button"),
        ("extensions", "unified-extensions-button"), ("menu", "PanelUI-button"),
    ].map { CatalogValue.Part($0.0, $0.1) }

    /// What fingerprinting protection LibreWolf asks for when sites may still see light or dark
    /// mode: every protection but the one that hides it.
    private static let allButColorScheme = "+AllTargets,-CSSPrefersColorScheme"

    /// LibreWolf's own themes, for light mode, dark mode and following macOS.
    private enum Theme {
        /// The compact light theme.
        static let light = "firefox-compact-light@mozilla.org"
        /// The compact dark theme.
        static let dark = "firefox-compact-dark@mozilla.org"
        /// The theme that follows macOS.
        static let system = "default-theme@mozilla.org"
    }

    /// `apps/librewolf.toml`. Malum always lets the add-ons in the policies run, which LibreWolf
    /// otherwise turns off, turns on `userChrome.css`, and never shows the bar that explains find
    /// as you type. It turns on the policies themselves when there are any.
    static let libreWolf = Catalog(
        file: Paths.appFile(named: "librewolf"),
        tables: libreWolfLook + libreWolfBrowsing + libreWolfData,
        always: [
            Catalog.Always(target: libreWolf("extensions.autoDisableScopes"), value: .integer(0)),
            Catalog.Always(
                target: libreWolf("toolkit.legacyUserProfileCustomizations.stylesheets"), value: .boolean(true)),
            Catalog.Always(target: libreWolf("accessibility.typeaheadfind.flashBar"), value: .integer(0)),
        ],
        arrange: LibreWolfPolicies.arrange)

    // swiftlint:disable no_magic_numbers
    // LibreWolf keeps these choices as numbers; each word names the number it writes.
    /// LibreWolf's tables about how it looks, its windows, what it opens and its privacy.
    private static let libreWolfLook = [
        CatalogTable(
            name: "appearance", about: "How LibreWolf looks.",
            settings: [
                CatalogSetting(
                    "mode",
                    "Light, dark, or following macOS, for LibreWolf's own look and for the sites that have both. "
                        + "\(Project.name) sets LibreWolf's compact theme to match.",
                    .choice([
                        CatalogChoice("dark", [.set(.integer(0)), .set(.integer(1)), .set(.string(Theme.dark))]),
                        CatalogChoice("light", [.set(.integer(1)), .set(.integer(0)), .set(.string(Theme.light))]),
                        CatalogChoice("system", [.set(.integer(2)), .remove, .set(.string(Theme.system))]),
                    ]),
                    [
                        libreWolf("layout.css.prefers-color-scheme.content-override"),
                        libreWolf("ui.systemUsesDarkTheme"), libreWolf("extensions.activeThemeID"),
                    ]),
                CatalogSetting(
                    "nova_design", "Whether LibreWolf uses the Nova redesign of its interface.", .flag,
                    [libreWolf("browser.nova.enabled")]),
            ]),
        CatalogTable(
            name: "window", about: "Closing and quitting LibreWolf.",
            settings: [
                CatalogSetting(
                    "close_with_last_tab", "Whether closing the last tab closes its window.", .flag,
                    [libreWolf("browser.tabs.closeWindowWithLastTab")]),
                CatalogSetting(
                    "quit_shortcut",
                    "What cmd+q does: quits at once, asks first, or nothing.",
                    .choice([
                        CatalogChoice("quit", [.set(.boolean(false)), .set(.boolean(false))]),
                        CatalogChoice("ask", [.set(.boolean(true)), .set(.boolean(false))]),
                        CatalogChoice("off", [.leave, .set(.boolean(true))]),
                    ]), [libreWolf("browser.warnOnQuitShortcut"), libreWolf("browser.quitShortcut.disabled")]),
            ]),
        CatalogTable(
            name: "startup", about: "What LibreWolf opens when it starts.",
            settings: [
                CatalogSetting(
                    "open", "The tabs of last time, the home page, or a blank page.",
                    .choice([
                        .word("last_session", .integer(3)), .word("home_page", .integer(1)),
                        .word("blank_page", .integer(0)),
                    ]), [libreWolf("browser.startup.page")])
            ]),
        CatalogTable(
            name: "privacy", about: "What LibreWolf hides from sites and clears.",
            settings: [
                CatalogSetting(
                    "fingerprinting",
                    "How LibreWolf hides what makes this Mac stand out to sites: \"resist\" is LibreWolf's strict "
                        + "default, which also hides dark mode and the time zone; \"protect\" is every other "
                        + "protection, so sites still see light or dark mode; \"off\" is none.",
                    .choice([
                        CatalogChoice("resist", [.set(.boolean(true)), .leave, .leave]),
                        CatalogChoice(
                            "protect", [.set(.boolean(false)), .set(.boolean(true)), .set(.string(allButColorScheme))]),
                        CatalogChoice("off", [.set(.boolean(false)), .set(.boolean(false)), .leave]),
                    ]),
                    [
                        libreWolf("privacy.resistFingerprinting"), libreWolf("privacy.fingerprintingProtection"),
                        libreWolf("privacy.fingerprintingProtection.overrides"),
                    ]),
                CatalogSetting(
                    "clear_on_quit",
                    "Whether LibreWolf clears cookies, history and the rest when it quits, as it does by default. "
                        + "Off keeps the tabs of last time.",
                    .flag, [libreWolf("privacy.sanitize.sanitizeOnShutdown")]),
            ]),
        CatalogTable(
            name: "extensions", about: "The add-ons LibreWolf installs and keeps, from addons.mozilla.org.",
            data: CatalogData(
                keys: "the add-on's name in its addons.mozilla.org address, such as ublock-origin",
                values: "the add-on's ID, which about:support lists, such as \"uBlock0@raymondhill.net\"",
                into: [AppConfig.policiesTable, LibreWolfPolicies.extensionSettings])),
    ]

    /// LibreWolf's tables about its tabs, toolbar, address bar, how it browses and uBlock Origin.
    private static let libreWolfBrowsing = [
        CatalogTable(
            name: "tabs", about: "Where LibreWolf shows its tabs.",
            settings: [
                CatalogSetting(
                    "vertical", "Whether the tabs are in the sidebar, down the side of the window, not along the top.",
                    .combinedFlag(
                        on: [.set(.boolean(true)), .set(.boolean(true))], off: [.leave, .set(.boolean(false))]),
                    [libreWolf("sidebar.revamp"), libreWolf(LibreWolfPolicies.verticalTabs)])
            ]),
        CatalogTable(
            name: "sidebar", about: "The sidebar's tools.",
            settings: [
                CatalogSetting(
                    "tools", "The tools the sidebar shows buttons for, in order, or none.",
                    .parts(sidebarTools, join: ",", none: "none"), [libreWolf("sidebar.main.tools")])
            ]),
        CatalogTable(
            name: "toolbar", about: "The toolbar with the address bar.",
            settings: [
                CatalogSetting(
                    "buttons",
                    "The toolbar's buttons, in order, with \"space\" for room that grows. "
                        + "\(Project.name) puts the add-ons' buttons in the extensions menu.",
                    .partList(toolbarButtons), [libreWolf(LibreWolfPolicies.toolbarState)])
            ]),
        CatalogTable(
            name: "bookmarks_toolbar", about: "The toolbar of bookmarks under the address bar.",
            settings: [
                CatalogSetting(
                    "show", "When it shows: never, always, or only on a new tab.",
                    .choice([
                        .word("never", .string("never")), .word("always", .string("always")),
                        .word("on_new_tab", .string("newtab")),
                    ]), [libreWolf("browser.toolbars.bookmarks.visibility")])
            ]),
        CatalogTable(
            name: "address_bar", about: "The buttons and suggestions under the address bar while you type.",
            settings: [
                CatalogSetting(
                    "show_tabs_button", "Whether there's a button to search the open tabs.", .flag,
                    [libreWolf("browser.urlbar.shortcuts.tabs")]),
                CatalogSetting(
                    "show_actions_button", "Whether there's a button to search LibreWolf's actions.", .flag,
                    [libreWolf("browser.urlbar.shortcuts.actions")]),
                CatalogSetting(
                    "suggest_search_engines", "Whether it suggests searching with another engine.", .flag,
                    [libreWolf("browser.urlbar.suggest.engines")]),
                CatalogSetting(
                    "suggest_quick_actions", "Whether it suggests actions, such as clearing history.", .flag,
                    [libreWolf("browser.urlbar.suggest.quickactions")]),
                CatalogSetting(
                    "suggest_top_sites", "Whether it suggests the sites you visit most.", .flag,
                    [libreWolf("browser.urlbar.suggest.topsites")]),
            ]),
        CatalogTable(
            name: "search", about: "Which search engine the address bar uses.",
            settings: [
                CatalogSetting(
                    "default_engine",
                    "The search engine's name, one of [search_engines] or one LibreWolf has, such as \"DuckDuckGo\".",
                    .text(.plain), [policy(LibreWolfPolicies.searchEngines, "Default")])
            ]),
        CatalogTable(
            name: "translations", about: "Which languages LibreWolf offers to translate.",
            settings: [
                CatalogSetting(
                    "never_translate", "The languages LibreWolf never offers to translate a page from.",
                    .parts(languages, join: ","), [libreWolf("browser.translations.neverTranslateLanguages")])
            ]),
        CatalogTable(
            name: "navigation", about: "What the keys that move around a page do.",
            settings: [
                CatalogSetting(
                    "backspace", "What backspace does outside a text field: goes back, scrolls up a page, or nothing.",
                    .choice([
                        .word("back", .integer(0)), .word("page_up", .integer(1)), .word("nothing", .integer(2)),
                    ]), [libreWolf("browser.backspace_action")])
            ]),
        CatalogTable(
            name: "video", about: "Video on pages.",
            settings: [
                CatalogSetting(
                    "picture_in_picture",
                    "Whether a video can play in a small window of its own, and shows the button for it.", .flag,
                    [
                        libreWolf("media.videocontrols.picture-in-picture.enabled"),
                        libreWolf("media.videocontrols.picture-in-picture.video-toggle.enabled"),
                    ])
            ]),
        CatalogTable(
            name: "websites", about: "What sites may use.",
            settings: [
                CatalogSetting(
                    "serial_ports", "Whether a site may ask to use a serial port, such as a tool that flashes a board.",
                    .flag, [libreWolf("dom.webserial.enabled")])
            ]),
        CatalogTable(
            name: "ublock_origin", about: "uBlock Origin's settings.",
            settings: [
                CatalogSetting(
                    "trust_my_filters",
                    "Whether the filters in [ublock_origin.filters] may use what uBlock Origin allows only trusted "
                        + "filters, such as scriptlets.",
                    .flagAs(on: LibreWolfPolicies.trustedFilters(true), off: LibreWolfPolicies.trustedFilters(false)),
                    [.file(LibreWolfPolicies.uBlockOrigin + ["userSettings"])])
            ]),
        CatalogTable(
            name: "css", about: "CSS that changes LibreWolf's own interface, such as hiding a button.",
            settings: [
                CatalogSetting(
                    "text", "The CSS, as it is.", .text(.plain),
                    [.file([LibreWolfPolicies.cssTable, LineBlock.textKey])])
            ]),
    ]

    // swiftlint:enable no_magic_numbers

    /// LibreWolf's data tables: bookmarks, search engines and uBlock Origin's filters.
    private static let libreWolfData = [
        CatalogTable(name: "bookmarks", about: "LibreWolf's bookmarks, in the parts below.", settings: []),
        CatalogTable(
            name: "bookmarks.menu", about: "The bookmarks in the Bookmarks menu, by title.",
            data: CatalogData(
                keys: "a bookmark's title", values: "its address",
                into: [AppConfig.policiesTable, LibreWolfPolicies.bookmarks, LibreWolfPolicies.Placement.menu])),
        CatalogTable(
            name: "bookmarks.toolbar", about: "The bookmarks on the bookmarks toolbar, by title.",
            data: CatalogData(
                keys: "a bookmark's title", values: "its address",
                into: [AppConfig.policiesTable, LibreWolfPolicies.bookmarks, LibreWolfPolicies.Placement.toolbar])),
        CatalogTable(
            name: "search_engines", about: "Search engines LibreWolf adds to its own, by name.",
            data: CatalogData(
                keys: "the engine's name",
                values: "its search address with %s for what you search, or a table of that address and a keyword "
                    + "that searches with it from the address bar, such as "
                    + "{ address = \"https://www.startpage.com/search?q=%s\", keyword = \"@sp\" }. "
                    + "\(Project.name) takes the icon from the site's favicon.ico",
                into: [AppConfig.policiesTable, LibreWolfPolicies.searchEngines, LibreWolfPolicies.addedEngines])),
        CatalogTable(
            name: "ublock_origin.filters", about: "uBlock Origin's own filters, by what they're for.",
            data: CatalogData(
                keys: "what the filters are for, which uBlock Origin shows as a comment above them",
                values:
                    "a filter in uBlock Origin's syntax, or a list of them, such as \"www.youtube.com##ytd-merch-shelf-renderer\"",
                into: LibreWolfPolicies.uBlockOrigin + ["toOverwrite", "filters"])),
    ]
}
