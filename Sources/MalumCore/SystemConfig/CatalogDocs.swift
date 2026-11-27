/// The parts of a catalog's reference page that every catalog shares: a section per table and an
/// entry per setting, made from the catalog so the page always matches what Malum reads.
enum CatalogDocs {
    /// The sections of every table in `catalog`, each setting's targets written by `place`.
    static func sections(of catalog: Catalog, place: (CatalogSetting.Target) -> String) -> String {
        catalog.tables.map { section($0, place: place) }.joined()
    }

    /// The part of the page about `table` and its settings, each setting's targets written by `place`.
    private static func section(_ table: CatalogTable, place: (CatalogSetting.Target) -> String) -> String {
        if let data = table.data {
            return heading(table.name, table.about) + "\n- Keys: \(data.keys)\n- Values: \(data.values)\n"
        }
        if let entries = table.entries {
            let name = "\(table.name).\(CatalogEntries.item("name"))"
            let optional = entries.optional.map { "`\($0)`" }.joined(separator: ", ")
            let needs = optional.isEmpty ? "every setting below" : "every setting below but \(optional)"
            return heading(name, table.about) + "\n- Names: \(entries.keys)\n- Each one needs \(needs).\n"
                + settings(entries.settings, place: place)
        }
        return heading(table.name, table.about) + settings(table.settings, place: place)
    }

    /// The heading of the table `name`, which is about `about`.
    private static func heading(_ name: String, _ about: String) -> String {
        "\n## `[\(name)]`\n\n\(about)\n"
    }

    /// The entries of `settings`, each one's targets written by `place`.
    private static func settings(_ settings: [CatalogSetting], place: (CatalogSetting.Target) -> String) -> String {
        settings.map { setting in
            let writes = setting.targets.map(place).joined(separator: ", ")
            let written = writes.isEmpty ? "" : "- Writes: \(writes)\n"
            return entry(setting.name, setting.about, value: setting.value.description) + written
        }.joined()
    }

    /// The part of the page about the setting `name`, which does `about` and takes `value`.
    static func entry(_ name: String, _ about: String, value: String) -> String {
        "\n### `\(name)`\n\n\(about)\n\n- Value: \(value)\n"
    }

    /// A preference target as the page names it, `domain` `key`, or a key in a file by its path.
    static func preference(_ target: CatalogSetting.Target) -> String {
        switch target {
        case .preference(let domain, let key):
            "`\(domain)` `\(key)`"
        case .file(let path):
            "`\(path.joined(separator: "."))`"
        case .fileKeys(let table, let value):
            "a key per shortcut in `\(table.joined(separator: "."))`, set to `\(value.toml)`"
        }
    }
}
