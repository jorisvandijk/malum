import Testing

@testable import MalumCore

/// LibreWolf's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    private static let libreWolf = "Library/Application Support/LibreWolf"
    private static let policies = "/Library/Preferences/net.librewolf.librewolf"
    private static let note = "Written by Malum from apps/librewolf.toml in dots. Changes made here are overwritten."
    /// What Malum always writes to `user.js`, in the file's order.
    private static let alwaysPrefs = [
        #"user_pref("accessibility.typeaheadfind.flashBar", 0);"#,
        #"user_pref("extensions.autoDisableScopes", 0);"#,
        #"user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);"#,
    ]

    /// What LibreWolf gets from its file: `user.js`, the policies by name, and the problems.
    private struct LibreWolfRead {
        let userJS: String?
        let policies: [String: String]
        let problems: [Message]
    }

    /// The `user.js` and policies `text` asks for, and the problems found in it.
    private func libreWolfRead(_ text: String) throws -> LibreWolfRead {
        let config = try #require(AppConfigs.app(named: "librewolf"))
        var reader = try TableReader(text, file: "apps/librewolf.toml")
        let read = config.read(&reader, home: "/Users/test")
        let userJS = read.files.first { $0.path.hasSuffix("user.js") }?.text
        var policies: [String: String] = [:]
        for preference in read.preferences where preference.domain == Self.policies {
            policies[preference.key] = preference.value
        }
        return LibreWolfRead(
            userJS: userJS, policies: policies, problems: reader.problems.map { Message($0.level, $0.text) })
    }

    @Test func libreWolfWritesItsProfile() throws {
        let (files, problems) = try read(
            """
            [appearance]
            mode = "dark"

            [startup]
            open = "last_session"

            [css]
            text = '''
            #alltabs-button { display: none !important; }
            '''
            """, app: "librewolf")
        #expect(problems.isEmpty)
        #expect(files.map(\.path).first == "\(Self.libreWolf)/profiles.ini")
        #expect(files.first?.onlyWhenMissing == true)
        #expect(files.first?.text.hasPrefix("[General]\nStartWithLastProfile=1\n\n[Profile0]\nDefault=1\n") == true)
        #expect(
            files.dropFirst()
                .first
                == AppFile(
                    "\(Self.libreWolf)/Profiles/default/compatibility.ini",
                    "[Compatibility]\nLastPlatformDir=/Applications/LibreWolf.app/Contents/Resources\n"
                        + "LastAppDir=/Applications/LibreWolf.app/Contents/Resources/browser\n",
                    onlyWhenMissing: true))
        let prefs = [
            #"user_pref("browser.startup.page", 3);"#,
            #"user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");"#,
            #"user_pref("layout.css.prefers-color-scheme.content-override", 0);"#,
            #"user_pref("ui.systemUsesDarkTheme", 1);"#,
        ]
        #expect(
            files.dropFirst(2) == [
                AppFile(
                    "\(Self.libreWolf)/Profiles/default/user.js",
                    "// \(Self.note)\n" + (prefs + Self.alwaysPrefs).sorted().joined(separator: "\n") + "\n"),
                AppFile(
                    "\(Self.libreWolf)/Profiles/default/chrome/userChrome.css",
                    "/* \(Self.note) */\n#alltabs-button { display: none !important; }\n"),
            ])
    }

    @Test func libreWolfWithNothingWritesWhatMalumAlwaysSetsAndNoPolicies() throws {
        let read = try libreWolfRead("")
        #expect(read.problems.isEmpty)
        #expect(read.userJS == "// \(Self.note)\n" + Self.alwaysPrefs.joined(separator: "\n") + "\n")
        #expect(read.policies.isEmpty)
    }

    @Test func libreWolfSystemModeLeavesOutTheDarkSwitch() throws {
        let read = try libreWolfRead("[appearance]\nmode = \"system\"\n")
        #expect(read.problems.isEmpty)
        #expect(read.userJS?.contains("ui.systemUsesDarkTheme") == false)
        #expect(read.userJS?.contains(#"user_pref("layout.css.prefers-color-scheme.content-override", 2);"#) == true)
    }

    @Test func libreWolfQuitShortcutSetsBothSwitches() throws {
        let ask = try libreWolfRead("[window]\nquit_shortcut = \"ask\"\n").userJS ?? ""
        #expect(ask.contains(#"user_pref("browser.warnOnQuitShortcut", true);"#))
        #expect(ask.contains(#"user_pref("browser.quitShortcut.disabled", false);"#))
        let off = try libreWolfRead("[window]\nquit_shortcut = \"off\"\n").userJS ?? ""
        #expect(!off.contains("browser.warnOnQuitShortcut"))
        #expect(off.contains(#"user_pref("browser.quitShortcut.disabled", true);"#))
    }

    @Test func libreWolfFingerprintingProtectLetsSitesSeeTheColorScheme() throws {
        let protect = try libreWolfRead("[privacy]\nfingerprinting = \"protect\"\n").userJS ?? ""
        #expect(protect.contains(#"user_pref("privacy.resistFingerprinting", false);"#))
        #expect(protect.contains(#"user_pref("privacy.fingerprintingProtection", true);"#))
        #expect(protect.contains(#""+AllTargets,-CSSPrefersColorScheme""#))
        let resist = try libreWolfRead("[privacy]\nfingerprinting = \"resist\"\n").userJS ?? ""
        #expect(resist.contains(#"user_pref("privacy.resistFingerprinting", true);"#))
        #expect(!resist.contains("privacy.fingerprintingProtection"))
    }

    @Test func libreWolfHorizontalTabsLeaveTheSidebarAlone() throws {
        let read = try libreWolfRead("[tabs]\nvertical = false\n[sidebar]\ntools = []\n")
        #expect(read.problems.isEmpty)
        #expect(read.userJS?.contains(#"user_pref("sidebar.verticalTabs", false);"#) == true)
        #expect(read.userJS?.contains("sidebar.revamp") == false)
        #expect(read.userJS?.contains(#"user_pref("sidebar.main.tools", "none");"#) == true)
        #expect(read.policies.isEmpty)
    }

    @Test func libreWolfWrongToolbarButtonIsAnError() throws {
        let read = try libreWolfRead("[toolbar]\nbuttons = [\"back\", \"pocket\"]\n")
        #expect(read.problems.count == 1)
        #expect(read.userJS?.contains("browser.uiCustomization.state") == false)
    }

    @Test func libreWolfRawPreferencesAreUnknown() throws {
        let read = try libreWolfRead("[settings]\n\"browser.startup.page\" = 3\n")
        #expect(read.problems == [Message(.warn, "unknown table settings")])
    }

    @Test func libreWolfExtensionsAreInstalledFromTheirAddress() throws {
        let read = try libreWolfRead(
            """
            [extensions]
            ublock-origin = "uBlock0@raymondhill.net"
            noscript = "{73a6fe31-595d-460b-a920-fcc0f8843232}"
            """)
        #expect(read.problems.isEmpty)
        #expect(read.policies["EnterprisePoliciesEnabled"]?.contains("<true/>") == true)
        let plist = try #require(read.policies["ExtensionSettings"])
        #expect(plist.contains("<key>uBlock0@raymondhill.net</key><dict>"))
        #expect(plist.contains("<key>{73a6fe31-595d-460b-a920-fcc0f8843232}</key><dict>"))
        #expect(
            plist.contains(
                "<key>install_url</key><string>https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi</string>"
            ))
        #expect(plist.contains("<key>installation_mode</key><string>force_installed</string>"))
    }

    @Test func libreWolfToolbarPutsTheExtensionsButtonsInTheirMenu() throws {
        let read = try libreWolfRead(
            """
            [extensions]
            ublock-origin = "uBlock0@raymondhill.net"
            noscript = "{73a6fe31-595d-460b-a920-fcc0f8843232}"

            [tabs]
            vertical = true

            [toolbar]
            buttons = ["back", "space", "address_bar", "menu"]
            """)
        #expect(read.problems.isEmpty)
        let line = try #require(
            read.userJS?.split(separator: "\n").first { $0.contains("browser.uiCustomization.state") })
        let addons =
            #"[\"_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action\", \"ublock0_raymondhill_net-browser-action\""#
        #expect(line.contains(#"\"nav-bar\": [\"back-button\", \"spring\", \"urlbar-container\", \"PanelUI-button\"]"#))
        #expect(line.contains(#"\"unified-extensions-area\": "# + addons + "]"))
        #expect(line.contains(#"\"seen\": "# + addons + #", \"developer-button\"]"#))
        #expect(line.contains(#"\"TabsToolbar\": []"#))
        #expect(read.userJS?.contains(#"user_pref("sidebar.revamp", true);"#) == true)
    }

    @Test func libreWolfToolbarKeepsTheTabsAlongTheTopWithoutVerticalTabs() throws {
        let read = try libreWolfRead("[toolbar]\nbuttons = [\"address_bar\"]\n")
        #expect(read.problems.isEmpty)
        #expect(read.userJS?.contains(#"\"TabsToolbar\": [\"firefox-view-button\", \"tabbrowser-tabs\""#) == true)
    }

    @Test func libreWolfBookmarksGoToTheMenuAndTheToolbarInTitleOrder() throws {
        let read = try libreWolfRead(
            """
            [bookmarks.menu]
            Sonarr = "https://sonarr.example.com"
            qBittorrent = "https://qbittorrent.example.com"
            "Home Assistant" = "https://ha.example.com"

            [bookmarks.toolbar]
            Mail = "https://mail.example.com"
            """)
        #expect(read.problems.isEmpty)
        let plist = try #require(read.policies["Bookmarks"])
        let titles = ["Home Assistant", "qBittorrent", "Sonarr", "Mail"].map {
            "<key>Title</key><string>\($0)</string>"
        }
        let positions = titles.compactMap { plist.range(of: $0)?.lowerBound }
        #expect(positions.count == titles.count && positions == positions.sorted())
        #expect(plist.contains("<key>Placement</key><string>toolbar</string>"))
    }

    @Test func libreWolfSearchEnginesTakeTheirIconFromTheSite() throws {
        let read = try libreWolfRead(
            """
            [search]
            default_engine = "Startpage"

            [search_engines]
            Startpage = { address = "https://www.startpage.com/search?q=%s", keyword = "@sp" }
            Plain = "https://plain.example.com/?q=%s"
            """)
        #expect(read.problems.isEmpty)
        let plist = try #require(read.policies["SearchEngines"])
        #expect(plist.contains("<key>Default</key><string>Startpage</string>"))
        #expect(
            plist.contains("<key>URLTemplate</key><string>https://www.startpage.com/search?q={searchTerms}</string>"))
        #expect(plist.contains("<key>IconURL</key><string>https://www.startpage.com/favicon.ico</string>"))
        #expect(plist.contains("<key>Alias</key><string>@sp</string>"))
        #expect(plist.components(separatedBy: "<key>Alias</key>").count == 2)
    }

    @Test func libreWolfFiltersFollowTheirComment() throws {
        let read = try libreWolfRead(
            """
            [ublock_origin]
            trust_my_filters = true

            [ublock_origin.filters]
            "YouTube merch shelf" = 'www.youtube.com##ytd-merch-shelf-renderer'
            "Google login prompts" = ['||accounts.google.com/gsi/iframe/*', 'accounts.google.com##.x']
            """)
        #expect(read.problems.isEmpty)
        let plist = try #require(read.policies["3rdparty"])
        let lines = [
            "! Google login prompts", "||accounts.google.com/gsi/iframe/*", "accounts.google.com##.x",
            "! YouTube merch shelf", "www.youtube.com##ytd-merch-shelf-renderer",
        ]
        #expect(plist.contains(lines.map { "<string>\($0)</string>" }.joined()))
        #expect(plist.contains("<array><string>userFiltersTrusted</string><string>true</string></array>"))
    }

    @Test func libreWolfWrongDataIsAnError() throws {
        let read = try libreWolfRead(
            """
            [extensions]
            "ublock origin" = "uBlock0@raymondhill.net"
            noscript = "noscript"

            [bookmarks.menu]
            Local = "file:///tmp"

            [search_engines]
            Broken = { address = "https://example.com/?q=" }

            [ublock_origin.filters]
            Empty = []
            """)
        #expect(read.policies["ExtensionSettings"] == nil)
        #expect(read.policies["Bookmarks"] == nil)
        #expect(
            read.problems == [
                Message(.error, "extensions.noscript should be \(MessageText.addonID)"),
                Message(.error, .addonName(TableReader.dotted(["extensions", "ublock origin"]))),
                Message(.error, "bookmarks.menu.Local should be \(MessageText.webAddress)"),
                Message(.error, "search_engines.Broken should be \(MessageText.searchEngine)"),
                Message(.error, "ublock_origin.filters.Empty should be a filter, or a list of them"),
            ])
    }
}
