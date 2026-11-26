import Testing

@testable import MalumCore

/// The shared catalog: value kinds, file targets and docs, through a made-up app.
@Suite(.timeLimit(.minutes(1)))
@MainActor
struct CatalogTests {
    /// A made-up app with a JSON settings file, a feed list and preferences, read through a catalog.
    static let app = AppConfig(
        name: "sample", domain: "com.example.sample",
        files: [
            AppConfigFile(".config/sample/settings.json", .json(table: "settings")),
            AppConfigFile(".config/sample/urls", .feeds(table: "feeds")),
        ],
        catalog: Catalog(
            file: "apps/sample.toml",
            tables: [
                CatalogTable(
                    name: "font", about: "The font.",
                    settings: [
                        CatalogSetting(
                            "delay_seconds", "The delay.", .seconds(6...72), [.file(["settings", "editor.saveDelay"])]),
                        CatalogSetting(
                            "family", "The family.",
                            .choice([.word("mono", .string("Menlo")), .word("sans", .string("Helvetica"))]),
                            [.file(["settings", "editor.fontFamily"])]),
                    ]),
                CatalogTable(
                    name: "editor", about: "The editor.",
                    settings: [
                        CatalogSetting(
                            "auto_save", "Saves.", .invertedFlag,
                            [.file(["settings", "files.noAutoSave"]), .domain("com.example.sample", "NoSave")]),
                        CatalogSetting("save_folder", "Where.", .path, [.file(["settings", "files.folder"])]),
                        CatalogSetting(
                            "delay", "Clashes.", .seconds(6...72), [.file(["settings", "editor.saveDelay"])]),
                    ]),
                CatalogTable(
                    name: "feeds", about: "Feeds.",
                    data: CatalogData(keys: "a title", values: "an address", into: ["feeds"])),
            ],
            always: [Catalog.Always(target: .file(["settings", "telemetry"]), value: .boolean(false))]))

    /// What the app gets from `toml`, and the problems found.
    private func read(_ toml: String) throws -> (settings: AppSettings, problems: [Message]) {
        var reader = try TableReader(toml, file: "apps/sample.toml")
        let settings = Self.app.read(&reader, home: "/Users/test")
        return (settings, reader.problems.map { Message($0.level, $0.text) })
    }

    /// The text of the file at `path` in `settings`.
    private func text(_ settings: AppSettings, _ path: String) -> String? {
        settings.files.first { $0.path == path }?.text
    }

    @Test func curatedTablesBecomeTheAppsOwnKeys() throws {
        let (settings, problems) = try read(
            "[font]\ndelay_seconds = 13\nfamily = \"mono\"\n[editor]\nauto_save = true\nsave_folder = \"$HOME/Notes\"\n"
        )
        #expect(problems.isEmpty)
        let json = try #require(text(settings, ".config/sample/settings.json"))
        #expect(json.contains("\"editor.saveDelay\": 13"))
        #expect(json.contains("\"editor.fontFamily\": \"Menlo\""))
        #expect(json.contains("\"files.noAutoSave\": false"))
        #expect(json.contains("\"files.folder\": \"/Users/test/Notes\""))
        #expect(json.contains("\"telemetry\": false"))
        #expect(settings.preferences.map(\.key) == ["NoSave"])
        #expect(settings.preferences.first?.setting == "editor.auto_save")
    }

    @Test func aDataTableGoesInAsItIs() throws {
        let (settings, problems) = try read("[feeds]\nNews = \"https://example.com/feed\"\n")
        #expect(problems.isEmpty)
        #expect(text(settings, ".config/sample/urls")?.contains("https://example.com/feed") == true)
    }

    @Test func wrongValuesRawTablesAndClashesAreProblems() throws {
        let (_, problems) = try read(
            "[font]\ndelay_seconds = 100\nsize = 1\n[editor]\ndelay = 14\n[settings]\n\"editor.saveDelay\" = 12\n[font2]\n"
        )
        #expect(
            problems == [
                Message(.warn, "unknown table font2"),
                Message(.warn, "unknown table settings"),
                Message(.warn, "unknown setting font.size"),
                Message(.error, "font.delay_seconds should be a whole number of seconds from 6 to 72"),
            ])
        let (_, clash) = try read("[font]\ndelay_seconds = 12\n[editor]\ndelay = 14\n")
        #expect(
            clash == [Message(.error, "editor.delay sets the same setting as font.delay_seconds, to something else")])
    }

    @Test func aKeyMalumAlwaysSetsCantBeAskedForTwice() throws {
        let catalog = Catalog(
            file: "apps/sample.toml",
            tables: [
                CatalogTable(
                    name: "privacy", about: "",
                    settings: [
                        CatalogSetting("telemetry", "", .flag, [.file(["settings", "telemetry"])])
                    ])
            ],
            always: [Catalog.Always(target: .file(["settings", "telemetry"]), value: .boolean(false))])
        var reader = try TableReader("[privacy]\ntelemetry = true\n", file: "apps/sample.toml")
        let reading = catalog.read(&reader, home: "/Users/test")
        _ = catalog.tables(reading.files, &reader)
        #expect(reader.problems.map(\.text) == [MessageText.alwaysSet("privacy.telemetry")])
    }

    @Test func numbersPathsAndColours() {
        let home = "/Users/test"
        func one(_ kind: CatalogValue, _ value: ConfigValue) -> ConfigValue? {
            guard case .set(let written)? = kind.writes(for: value, targets: 1, home: home)?.first else { return nil }
            return written
        }
        #expect(one(.seconds(1...10), .integer(10)) == .integer(10))
        #expect(one(.minutes(0...Int.max), .integer(-1)) == nil)
        #expect(one(.path, .string("$HOME/Git")) == .string("/Users/test/Git"))
        #expect(one(.path, .string("/opt/homebrew")) == .string("/opt/homebrew"))
        #expect(one(.path, .string("~/Git")) == nil)
        #expect(one(.path, .string("/Users/test/Git")) == nil)
        #expect(one(.path, .string("$HOME/")) == nil)
        #expect(one(.color, .string("#f8f8f2")) == .string("#f8f8f2"))
        #expect(one(.color, .string("#F8F8F2")) == nil)
        #expect(one(.color, .string("#fff")) == nil)
        let pair = ConfigValue.table(["fg": .string("#f8f8f2"), "bg": .string("#282a36"), "style": .string("bold")])
        #expect(one(.colorPair(join: ","), pair) == .string("bold #f8f8f2,#282a36"))
        #expect(one(.colorPair(join: ","), .table(["fg": .string("#f8f8f2")])) == .string("#f8f8f2"))
        #expect(one(.colorPair(join: ","), .table(["fg": .string("#f8f8f2"), "shade": .string("x")])) == nil)
        #expect(one(.colorPair(join: ","), .table(["bg": .string("#f8f8f2")])) == nil)
        #expect(one(.colorPair(join: ","), .table(["fg": .string("#f8f8f2"), "style": .string("wavy")])) == nil)
    }

    @Test func shortcutsUseTheKeyboardsNames() throws {
        let kitty = ShortcutStyle.text(
            names: [.ctrl: "ctrl", .option: "alt", .cmd: "cmd", .shift: "shift"], joiner: "+")
        #expect(ShortcutStyle.shared.value(try #require(Hotkey("option+ctrl+k"))) == .string("ctrl+option+k"))
        #expect(kitty.value(try #require(Hotkey("cmd+option+k"))) == .string("alt+cmd+k"))
        #expect(
            ShortcutStyle.carbonJSON.value(try #require(Hotkey("cmd+x")))
                == .string("{\"carbonKeyCode\":7,\"carbonModifiers\":256}"))
        #expect(
            ShortcutStyle.carbonTable(keyCode: "keyCode", modifiers: "modifiers").value(
                try #require(Hotkey("ctrl+option+k")))
                == .table(["keyCode": .integer(40), "modifiers": .integer(6144)]))
        #expect(Hotkey("hyper+space")?.modifiers == Set(Modifier.allCases))
        #expect(Hotkey("f5")?.modifiers == [])
        for wrong in ["", "ctrl+", "ctrl+ctrl+k", "hyper+cmd+k", "Ctrl+k", "ctrl+kk", "super+k"] {
            #expect(Hotkey(wrong) == nil, "\(wrong)")
        }
    }

    @Test func theDocsListEveryTableAndWhereItWrites() throws {
        let page = AppDocs.page(Self.app, try #require(Self.app.catalog))
        #expect(page.contains("# sample settings reference"))
        #expect(page.contains("## `[font]`"))
        #expect(page.contains("- Value: a whole number of seconds from 6 to 72"))
        #expect(page.contains("- Writes: `$HOME/.config/sample/settings.json` `editor.saveDelay`"))
        #expect(page.contains("`com.example.sample` `NoSave`"))
        #expect(page.contains("- Keys: a title\n- Values: an address"))
    }

    @Test func everyAppsCatalogWritesFilesTheAppHasAndPagesAreMade() {
        for app in AppConfigs.all + [Self.app] {
            guard let catalog = app.catalog else { continue }
            let tables = Set(app.files.flatMap(\.tables))
            let targets = catalog.tables.flatMap(\.settings).flatMap(\.targets) + catalog.always.map(\.target)
            for case .file(let path) in targets {
                #expect(path.first.map(tables.contains) == true, "\(app.name) \(path)")
            }
            for data in catalog.tables.compactMap(\.data) {
                #expect(data.into.first.map(tables.contains) == true, "\(app.name) \(data.into)")
            }
        }
        #expect(AppDocs.pages().count == AppConfigs.all.filter { $0.catalog != nil }.count)
    }
}
