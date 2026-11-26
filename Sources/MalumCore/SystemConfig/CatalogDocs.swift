/// The parts of a catalog's reference page that every catalog shares: a section per table and an
/// entry per setting, made from the catalog so the page always matches what Malum reads.
enum CatalogDocs {
    /// The sections of every table in `catalog`, each setting's targets written by `place`.
    static func sections(of catalog: Catalog, place: (CatalogSetting.Target) -> String) -> String {
        catalog.tables.map { section($0, place: place) }.joined()
    }

    /// The part of the page about `table` and its settings, each setting's targets written by `place`.
    private static func section(_ table: CatalogTable, place: (CatalogSetting.Target) -> String) -> String {
        let heading = "\n## `[\(table.name)]`\n\n\(table.about)\n"
        if let data = table.data {
            return heading + "\n- Keys: \(data.keys)\n- Values: \(data.values)\n"
        }
        let settings = table.settings.map { setting in
            let writes = setting.targets.map(place).joined(separator: ", ")
            return entry(setting.name, setting.about, value: setting.value.description) + "- Writes: \(writes)\n"
        }
        return heading + settings.joined()
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
