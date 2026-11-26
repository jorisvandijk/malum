/// Reading the curated tables of `macos.toml`.
extension MacOSCatalog {
    /// A preference to set or remove, with the key in `macos.toml` that asks for it.
    struct Wanted: Equatable {
        /// The key that asks for it, such as `pointer.natural_scrolling`, or none for one Malum
        /// always sets.
        let path: [String]
        /// The preference.
        let preference: AppPreference
    }

    /// The preferences the curated tables in `reader`'s file ask for, adding a problem to `reader`
    /// for each value that's wrong and a warning for each key no table takes.
    static func read(_ reader: inout TableReader) -> [Wanted] {
        var wanted: [Wanted] = []
        for table in tables where reader.document[table.name] != nil {
            let fields = reader.table(reader.document, table.name, at: [])
            reader.unknownKeys(fields, at: [table.name], known: table.settings.map(\.name))
            for setting in table.settings {
                guard let given = fields[setting.name] else { continue }
                let path = [table.name, setting.name]
                guard let writes = setting.writes(for: given) else {
                    reader.expect(path, setting.value)
                    continue
                }
                wanted += preferences(writes, of: setting, at: path)
            }
        }
        return wanted
    }

    /// The preferences Malum always sets.
    static var always: [Wanted] {
        alwaysSet.compactMap { target, value in
            PlistText.document(value).map {
                Wanted(path: [], preference: AppPreference(domain: target.domain, key: target.key, value: $0))
            }
        }
    }

    /// The preferences `writes` asks for, one for each of `setting`'s targets that isn't left as
    /// it is, set from the key `path`.
    private static func preferences(
        _ writes: [MacOSSetting.Write], of setting: MacOSSetting, at path: [String]
    ) -> [Wanted] {
        let name = TableReader.dotted(path)
        return zip(setting.targets, writes).compactMap { target, write in
            let value: String?
            switch write {
            case .set(let given):
                guard let document = PlistText.document(given) else { return nil }
                value = document
            case .remove:
                value = nil
            case .leave:
                return nil
            }
            let preference = AppPreference(domain: target.domain, key: target.key, value: value, setting: name)
            return Wanted(path: path, preference: preference)
        }
    }
}
