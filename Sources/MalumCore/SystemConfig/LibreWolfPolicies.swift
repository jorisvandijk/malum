import Foundation

/// What LibreWolf's catalog can't write key by key: its policies take add-ons, bookmarks, search
/// engines and uBlock Origin's filters as lists of tables, and its toolbar is one JSON text that
/// also names the add-ons' buttons. The catalog's data tables and settings put what the file says
/// where these go, and `arrange` turns it into what LibreWolf reads.
enum LibreWolfPolicies {
    /// The table of preferences written to `user.js`.
    static let settingsTable = "settings"
    /// The table of CSS written to `userChrome.css`.
    static let cssTable = "css"
    /// The policy LibreWolf ignores the rest without.
    private static let policiesEnabled = "EnterprisePoliciesEnabled"
    /// The policy that installs add-ons.
    static let extensionSettings = "ExtensionSettings"
    /// The policy that adds bookmarks.
    static let bookmarks = "Bookmarks"
    /// The policy that adds search engines and picks the default one.
    static let searchEngines = "SearchEngines"
    /// The key of `searchEngines` that lists the engines it adds.
    static let addedEngines = "Add"
    /// The preference that puts the tabs in the sidebar.
    static let verticalTabs = "sidebar.verticalTabs"
    /// The preference that holds the toolbar's layout.
    static let toolbarState = "browser.uiCustomization.state"
    /// uBlock Origin's add-on ID.
    static let uBlockOriginID = "uBlock0@raymondhill.net"
    /// Where uBlock Origin's policies go.
    static let uBlockOrigin = [AppConfig.policiesTable, "3rdparty", "Extensions", uBlockOriginID]

    /// Where a bookmark goes, by the name LibreWolf's policy gives it.
    enum Placement {
        /// The Bookmarks menu.
        static let menu = "menu"
        /// The bookmarks toolbar.
        static let toolbar = "toolbar"
        /// Both, in the order the policy lists them.
        static let all = [menu, toolbar]
    }

    /// The tables of the file the data goes in, for the problems found in it.
    private enum Source {
        /// The add-ons.
        static let extensions = ["extensions"]
        /// The bookmarks, with a part per placement.
        static let bookmarks = ["bookmarks"]
        /// The search engines.
        static let searchEngines = ["search_engines"]
        /// uBlock Origin's filters.
        static let filters = ["ublock_origin", "filters"]
    }

    /// Where an add-on is downloaded from, by its name in its addons.mozilla.org address.
    private static func addonDownload(_ name: String) -> String {
        "https://addons.mozilla.org/firefox/downloads/latest/\(name)/latest.xpi"
    }
    /// What the policy keeps an add-on installed with.
    private static let forceInstalled = "force_installed"
    /// How uBlock Origin marks a line of its filters as a comment.
    private static let filterComment = "! "
    /// What a search address holds for what's searched.
    private static let searchTerms = "%s"
    /// What LibreWolf takes in place of `searchTerms`.
    private static let libreWolfSearchTerms = "{searchTerms}"

    /// uBlock Origin's setting that trusts its own filters, as `on` says.
    static func trustedFilters(_ on: Bool) -> ConfigValue {
        .array([.array([.string("userFiltersTrusted"), .string(String(on))])])
    }

    /// `tables` with the add-ons, bookmarks, search engines, uBlock Origin's filters and the toolbar
    /// in the form LibreWolf reads, with a problem in `reader` for each that's wrong. When there are
    /// policies, it turns them on.
    static func arrange(_ tables: ConfigTable, _ reader: inout TableReader) -> ConfigTable {
        var tables = tables
        let policies = [AppConfig.policiesTable]
        let addons = self.addons(tables.value(at: policies + [extensionSettings]), &reader)
        tables.set(addons.isEmpty ? nil : .table(installs(addons)), at: policies + [extensionSettings])
        let marks = self.marks(tables.value(at: policies + [bookmarks]), &reader)
        tables.set(marks.isEmpty ? nil : .array(marks), at: policies + [bookmarks])
        let engines = self.engines(tables.value(at: policies + [searchEngines, addedEngines]), &reader)
        tables.set(engines.isEmpty ? nil : .array(engines), at: policies + [searchEngines, addedEngines])
        let filterPath = uBlockOrigin + ["toOverwrite", "filters"]
        let filters = self.filters(tables.value(at: filterPath), &reader)
        tables.set(filters.isEmpty ? nil : .array(filters.map(ConfigValue.string)), at: filterPath)
        if case .table(let set)? = tables[AppConfig.policiesTable], !set.isEmpty {
            tables.set(.boolean(true), at: policies + [policiesEnabled])
        }
        let statePath = [settingsTable, toolbarState]
        if case .array(let buttons)? = tables.value(at: statePath) {
            let vertical = tables.value(at: [settingsTable, verticalTabs]) == .boolean(true)
            let state = toolbar(buttons, addons: addons.map(\.id), vertical: vertical)
            tables.set(JSONText.value(state).map(ConfigValue.string), at: statePath)
        }
        return tables
    }

    // MARK: - Add-ons

    /// One add-on: its name in its addons.mozilla.org address and its ID.
    private struct Addon {
        /// The name in its address, such as `ublock-origin`.
        let name: String
        /// Its ID, such as `uBlock0@raymondhill.net`.
        let id: String
    }

    /// The add-ons in `value`, by name, with a problem in `reader` for each that's wrong.
    private static func addons(_ value: ConfigValue?, _ reader: inout TableReader) -> [Addon] {
        guard case .table(let table)? = value else { return [] }
        return table.keys.sorted().compactMap { name in
            let path = Source.extensions + [name]
            guard isAddonName(name) else {
                reader.add(.error, at: path, .addonName(TableReader.dotted(path)))
                return nil
            }
            guard case .string(let id)? = table[name], isAddonID(id) else {
                reader.expect(path, MessageText.addonID)
                return nil
            }
            return Addon(name: name, id: id)
        }
    }

    /// What the policy installs for `addons`, by ID.
    private static func installs(_ addons: [Addon]) -> ConfigTable {
        var installs: ConfigTable = [:]
        for addon in addons {
            installs[addon.id] = .table([
                "installation_mode": .string(forceInstalled),
                "install_url": .string(addonDownload(addon.name)),
            ])
        }
        return installs
    }

    /// Whether `name` can be the name of an add-on in its addons.mozilla.org address.
    private static func isAddonName(_ name: String) -> Bool {
        !name.isEmpty && name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }
    }

    /// Whether `id` is an add-on's ID: a name and a domain joined by `@`, or a UUID in braces.
    private static func isAddonID(_ id: String) -> Bool {
        guard !id.contains(where: \.isWhitespace) else { return false }
        if id.hasPrefix("{"), id.hasSuffix("}") { return UUID(uuidString: String(id.dropFirst().dropLast())) != nil }
        let parts = id.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == idParts && parts.allSatisfy { !$0.isEmpty }
    }

    /// How many parts an add-on's ID of a name and a domain has.
    private static let idParts = 2

    /// The name LibreWolf gives the toolbar button of the add-on `id`.
    private static func buttonID(of id: String) -> String {
        let name = id.lowercased().map { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") ? $0 : "_" }
        return String(name) + "-browser-action"
    }

    // MARK: - Toolbar

    /// The toolbar's layout, with `buttons` on it and the buttons of `addons` in the extensions
    /// menu, with the tabs in the sidebar when it's `vertical` or along the top otherwise.
    private static func toolbar(_ buttons: [ConfigValue], addons: [String], vertical: Bool) -> ConfigValue {
        let addonButtons = addons.map { ConfigValue.string(buttonID(of: $0)) }
        let tabs = vertical ? [] : ["firefox-view-button", "tabbrowser-tabs", "new-tab-button", "alltabs-button"]
        let placements: ConfigTable = [
            "nav-bar": .array(buttons),
            "unified-extensions-area": .array(addonButtons),
            "PersonalToolbar": .array([.string("personal-bookmarks")]),
            "TabsToolbar": .array(tabs.map(ConfigValue.string)),
            "toolbar-menubar": .array([.string("menubar-items")]),
            "widget-overflow-fixed-list": .array([]),
        ]
        // Buttons LibreWolf has seen aren't added to the toolbar again; the developer tools' button
        // would be otherwise, as would each add-on's.
        return .table([
            "currentVersion": .integer(toolbarVersion),
            "newElementCount": .integer(0),
            "dirtyAreaCache": .array([.string("nav-bar"), .string("unified-extensions-area")]),
            "seen": .array(addonButtons + [.string("developer-button")]),
            "placements": .table(placements),
        ])
    }

    /// The version of the toolbar's layout LibreWolf writes, which it updates from when it's older.
    private static let toolbarVersion = 20

    // MARK: - Bookmarks

    /// The bookmarks in `value`, a table per placement of addresses by title, as the policy lists
    /// them, with a problem in `reader` for each that's wrong.
    private static func marks(_ value: ConfigValue?, _ reader: inout TableReader) -> [ConfigValue] {
        guard case .table(let placements)? = value else { return [] }
        return Placement.all.flatMap { placement -> [ConfigValue] in
            guard case .table(let marks)? = placements[placement] else { return [] }
            return byTitle(marks).compactMap { title, address in
                let path = Source.bookmarks + [placement, title]
                guard case .string(let url) = address, WebAddress.url(url) != nil else {
                    reader.expect(path, MessageText.webAddress)
                    return nil
                }
                return .table(["Title": .string(title), "URL": .string(url), "Placement": .string(placement)])
            }
        }
    }

    // MARK: - Search engines

    /// The search engines in `value`, by name, as the policy lists them, with a problem in `reader`
    /// for each that's wrong.
    private static func engines(_ value: ConfigValue?, _ reader: inout TableReader) -> [ConfigValue] {
        guard case .table(let engines)? = value else { return [] }
        return byTitle(engines).compactMap { name, given in
            let path = Source.searchEngines + [name]
            guard let (address, keyword) = engine(given), let url = WebAddress.url(address), let host = url.host,
                let scheme = url.scheme, address.contains(searchTerms)
            else {
                reader.expect(path, MessageText.searchEngine)
                return nil
            }
            var engine: ConfigTable = [
                "Name": .string(name),
                "URLTemplate": .string(address.replacingOccurrences(of: searchTerms, with: libreWolfSearchTerms)),
                "Method": .string("GET"),
                "IconURL": .string("\(scheme)://\(host)/favicon.ico"),
            ]
            if let keyword { engine["Alias"] = .string(keyword) }
            return .table(engine)
        }
    }

    /// The address and keyword of the engine `given`, which is an address or a table of one and
    /// an optional keyword, or nil when it's neither.
    private static func engine(_ given: ConfigValue) -> (address: String, keyword: String?)? {
        switch given {
        case .string(let address):
            return (address, nil)
        case .table(let table):
            guard Set(table.keys).isSubset(of: ["address", "keyword"]), case .string(let address)? = table["address"]
            else { return nil }
            switch table["keyword"] {
            case nil:
                return (address, nil)
            case .string(let keyword)? where !keyword.isEmpty && !keyword.contains(where: \.isWhitespace):
                return (address, keyword)
            default:
                return nil
            }
        default:
            return nil
        }
    }

    // MARK: - Filters

    /// uBlock Origin's filters in `value`, each group after its comment, with a problem in `reader`
    /// for each group that's wrong.
    private static func filters(_ value: ConfigValue?, _ reader: inout TableReader) -> [String] {
        guard case .table(let groups)? = value else { return [] }
        return byTitle(groups).flatMap { title, given -> [String] in
            let lines: [String]
            if case .string(let line) = given { lines = [line] } else { lines = TableReader.texts(given) ?? [] }
            guard !lines.isEmpty, lines.allSatisfy({ !$0.isEmpty }) else {
                reader.expect(Source.filters + [title], MessageText.filters)
                return []
            }
            return [filterComment + title] + lines
        }
    }

    // MARK: - Shared

    /// The entries of `table` in the order a person reads titles, without minding capitals.
    private static func byTitle(_ table: ConfigTable) -> [(key: String, value: ConfigValue)] {
        table.sorted { ($0.key.lowercased(), $0.key) < ($1.key.lowercased(), $1.key) }
    }
}
