/// The curated settings of one file in dots, by table, such as `[pointer]` in `macos.toml` or
/// `[font]` in an app's file. Each one says what it writes, a preference or a key in one of the
/// app's own files, so a person never needs the names an app stores its settings under. A setting
/// an app has that isn't here is added here, not set by its raw name.
struct Catalog: Sendable {
    /// One value Malum always writes, whatever the file says.
    struct Always: Sendable {
        /// Where it's written.
        let target: CatalogSetting.Target
        /// What's written there.
        let value: ConfigValue
    }

    /// The file the catalog reads, such as `macos.toml` or `apps/kitty.toml`.
    let file: String
    /// Every curated table, in the order the file and the docs show them.
    let tables: [CatalogTable]
    /// The values Malum always writes, whatever the file says.
    let always: [Always]
    /// The problem for the key at a path, written dotted, that asks for another value where Malum
    /// always writes one.
    let alwaysConflict: @Sendable (String) -> MessageText
    /// Turns the tables the settings wrote into the ones the app's files read, for an app that keeps
    /// what one setting asks for in a form of its own, such as LibreWolf's policies, adding each
    /// problem it finds to the reader. Nil when the tables are right as they are.
    let arrange: (@Sendable (ConfigTable, inout TableReader) -> ConfigTable)?

    /// Creates the catalog of `file`, with its `tables`, which always writes `always`; a key that
    /// asks for something else there gets `alwaysConflict`. What the settings write is put in the
    /// app's form by `arrange` when that's set.
    init(
        file: String, tables: [CatalogTable], always: [Always] = [],
        alwaysConflict: @escaping @Sendable (String) -> MessageText = MessageText.alwaysSet,
        arrange: (@Sendable (ConfigTable, inout TableReader) -> ConfigTable)? = nil
    ) {
        self.file = file
        self.tables = tables
        self.always = always
        self.alwaysConflict = alwaysConflict
        self.arrange = arrange
    }

    /// The names of the tables at the top of the file, without the parts inside them.
    var topTables: [String] {
        tables.filter { $0.path.count == 1 }.map(\.name)
    }

    /// The names of the parts inside the table at `path`, such as `normal` and `bright` in
    /// `[colors]`.
    func parts(of path: [String]) -> [String] {
        tables.compactMap { $0.path.dropLast() == path[...] ? $0.path.last : nil }
    }

    /// The curated setting that writes `target`, as `table.name`, or nil when none does.
    func setting(writing target: CatalogSetting.Target) -> String? {
        for table in tables {
            guard let setting = table.settings.first(where: { $0.targets.contains(target) }) else { continue }
            return TableReader.dotted([table.name, setting.name])
        }
        return nil
    }
}

/// One curated table in a file in dots, such as `[trackpad]`, and the settings it takes. A data
/// table, such as `[feeds]`, holds names the person chooses instead of settings, and an entries
/// table, such as `[keys]`, holds tables by such names. A table's name may name a part of another
/// one, such as `colors.normal`, which that one's table holds.
struct CatalogTable: Sendable {
    /// The table's name, dotted for a part of another table.
    let name: String
    /// What the table is about, in a sentence for the docs.
    let about: String
    /// Its settings, in the order the docs show them, none for a data table.
    let settings: [CatalogSetting]
    /// What a data table holds and where it goes, or nil when the table holds settings.
    let data: CatalogData?
    /// What each entry of an entries table holds, or nil when the table holds settings.
    let entries: CatalogEntries?

    /// Creates the table `name`, about `about`, which takes `settings`.
    init(name: String, about: String, settings: [CatalogSetting]) {
        self.init(name: name, about: about, settings: settings, data: nil, entries: nil)
    }

    /// Creates the data table `name`, about `about`, which holds what `data` says.
    init(name: String, about: String, data: CatalogData) {
        self.init(name: name, about: about, settings: [], data: data, entries: nil)
    }

    /// Creates the entries table `name`, about `about`, each entry of which holds what `entries`
    /// says.
    init(name: String, about: String, entries: CatalogEntries) {
        self.init(name: name, about: about, settings: [], data: nil, entries: entries)
    }

    private init(
        name: String, about: String, settings: [CatalogSetting], data: CatalogData?, entries: CatalogEntries?
    ) {
        self.name = name
        self.about = about
        self.settings = settings
        self.data = data
        self.entries = entries
    }

    /// Where the table is in the file, such as `["colors", "normal"]`.
    var path: [String] {
        name.split(separator: ".").map(String.init)
    }
}

/// What each entry of an entries table holds, such as a key in `[keys.github]` of
/// `apps/ssh.toml`: a table by a name the person chooses, which needs every one of `settings`. A
/// target of a setting may hold `item(each)`, written once for each item of the entry's list
/// setting `each`, such as once for each host a key is for.
struct CatalogEntries: Sendable {
    /// What an entry's name is, for the docs, such as "a name for the key".
    let keys: String
    /// The settings each entry needs.
    let settings: [CatalogSetting]
    /// The list setting whose items fill in `item(each)` in the targets, or nil when none does.
    let each: String?

    /// What stands in a target for each item of the list setting `name`.
    static func item(_ name: String) -> String {
        "<\(name)>"
    }
}

/// What a data table holds, such as feeds by title, and the table of the app's file it goes into
/// as it is.
struct CatalogData: Sendable {
    /// What its keys are, for the docs, such as "a feed's title".
    let keys: String
    /// What its values are, for the docs, such as "the feed's address".
    let values: String
    /// The table the app's file formats read it from, such as `["feeds"]`.
    let into: [String]
}
