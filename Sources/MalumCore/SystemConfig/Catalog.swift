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

    /// Creates the catalog of `file`, with its `tables`, which always writes `always`; a key that
    /// asks for something else there gets `alwaysConflict`.
    init(
        file: String, tables: [CatalogTable], always: [Always] = [],
        alwaysConflict: @escaping @Sendable (String) -> MessageText = MessageText.alwaysSet
    ) {
        self.file = file
        self.tables = tables
        self.always = always
        self.alwaysConflict = alwaysConflict
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
/// table, such as `[feeds]`, holds names the person chooses instead of settings.
struct CatalogTable: Sendable {
    /// The table's name.
    let name: String
    /// What the table is about, in a sentence for the docs.
    let about: String
    /// Its settings, in the order the docs show them, none for a data table.
    let settings: [CatalogSetting]
    /// What a data table holds and where it goes, or nil when the table holds settings.
    let data: CatalogData?

    /// Creates the table `name`, about `about`, which takes `settings`.
    init(name: String, about: String, settings: [CatalogSetting]) {
        self.name = name
        self.about = about
        self.settings = settings
        self.data = nil
    }

    /// Creates the data table `name`, about `about`, which holds what `data` says.
    init(name: String, about: String, data: CatalogData) {
        self.name = name
        self.about = about
        self.settings = []
        self.data = data
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
