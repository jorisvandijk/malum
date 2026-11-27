/// Reading the curated tables of a file in dots.
extension Catalog {
    /// A preference to set or remove, with the key in the file that asks for it.
    struct Wanted: Equatable {
        /// The key that asks for it, such as `pointer.natural_scrolling`, or none for one Malum
        /// always sets.
        let path: [String]
        /// The preference.
        let preference: AppPreference
    }

    /// A value for a key in one of the app's own files, with the key in dots that asks for it.
    struct FileValue: Equatable {
        /// The key that asks for it, or none for one Malum always sets.
        let path: [String]
        /// Where it goes in the tables the app's files are written from.
        let target: [String]
        /// The value.
        let value: ConfigValue
    }

    /// What the curated tables of a file ask for.
    struct Reading {
        /// The preferences, Malum's own first.
        var preferences: [Wanted] = []
        /// The keys of the app's files, Malum's own first.
        var files: [FileValue] = []
    }

    /// What the curated tables in `reader`'s file ask for, Malum's own values first, adding a problem
    /// to `reader` for each value that's wrong and a warning for each key no table takes. A path in
    /// the home folder is filled in with `home`, and each preference value is written by `document`.
    func read(
        _ reader: inout TableReader, home: String, document: (ConfigValue) -> String? = PlistText.document
    ) -> Reading {
        var reading = Reading()
        for item in always {
            reading.add(.set(item.value), to: item.target, at: [], document: document)
        }
        for table in tables {
            guard let fields = Self.fields(at: table.path, in: reader.document, &reader) else { continue }
            if let data = table.data {
                reading.files += fields.sorted { $0.key < $1.key }.map {
                    FileValue(path: table.path + [$0.key], target: data.into + [$0.key], value: $0.value)
                }
                continue
            }
            if let entries = table.entries {
                for item in entryWrites(fields, of: entries, at: table.path, &reader, home: home) {
                    reading.add(item.write, to: item.target, at: item.path, document: document)
                }
                continue
            }
            reader.unknownKeys(fields, at: table.path, known: table.settings.map(\.name) + parts(of: table.path))
            for setting in table.settings {
                guard let given = fields[setting.name] else { continue }
                let path = table.path + [setting.name]
                guard let writes = setting.writes(for: given, home: home) else {
                    reader.expect(path, setting.value)
                    continue
                }
                for (target, write) in zip(setting.targets, writes) {
                    reading.add(write, to: target, at: path, document: document)
                }
            }
        }
        return reading
    }

    /// The tables Malum's own code reads, from what the curated tables in `reader`'s file ask for,
    /// for a file whose settings Malum acts on itself, such as `keyboard.toml`, with the problems
    /// `read(_:home:document:)` and `tables(_:_:)` find. A path in the home folder is filled in with
    /// `home`.
    func own(_ reader: inout TableReader, home: String) -> ConfigTable {
        tables(read(&reader, home: home).files, &reader)
    }

    /// One thing an entry of an entries table writes, with the key in dots that asks for it.
    private struct EntryWrite {
        /// The key that asks for it, such as `keys.github.file`.
        let path: [String]
        /// Where it's written.
        let target: CatalogSetting.Target
        /// What's written there.
        let write: CatalogSetting.Write
    }

    /// What the entries in `fields`, the entries table at `path`, write, with an error in `reader`
    /// for each setting an entry lacks or has wrong and a warning for each key it shouldn't have. A
    /// path in the home folder is filled in with `home`.
    private func entryWrites(
        _ fields: ConfigTable, of entries: CatalogEntries, at path: [String], _ reader: inout TableReader,
        home: String
    ) -> [EntryWrite] {
        var writes: [EntryWrite] = []
        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            guard let entry = reader.table(value, at: path + [name]) else { continue }
            writes += self.writes(of: entry, in: entries, at: path + [name], &reader, home: home)
        }
        return writes
    }

    /// What the entry `entry`, at `path`, writes, with the problems `entryWrites(_:of:at:_:home:)`
    /// finds.
    private func writes(
        of entry: ConfigTable, in entries: CatalogEntries, at path: [String], _ reader: inout TableReader,
        home: String
    ) -> [EntryWrite] {
        reader.unknownKeys(entry, at: path, known: entries.settings.map(\.name))
        var wanted: [(setting: CatalogSetting, writes: [CatalogSetting.Write])] = []
        var items: [String] = []
        for setting in entries.settings {
            guard let given = entry[setting.name] else {
                if !entries.optional.contains(setting.name) {
                    reader.add(.error, at: path, .needs(TableReader.dotted(path), setting.name))
                }
                continue
            }
            guard let writes = setting.writes(for: given, home: home) else {
                reader.expect(path + [setting.name], setting.value)
                continue
            }
            if setting.name == entries.each { items = TableReader.texts(given) ?? [] }
            wanted.append((setting, writes))
        }
        let item = entries.each.map(CatalogEntries.item)
        let name = path.last ?? ""
        return wanted.flatMap { setting, writes in
            zip(setting.targets, writes).flatMap { target, write in
                target.filled(CatalogEntries.entry, with: [name]).flatMap { $0.filled(item, with: items) }.map {
                    EntryWrite(path: path + [setting.name], target: $0, write: write)
                }
            }
        }
    }

    /// The table at `path` in `document`, or nil when it's missing. One that isn't a table is an
    /// error in `reader`; a table it's a part of that isn't one is the error of that table.
    private static func fields(at path: [String], in document: ConfigTable, _ reader: inout TableReader)
        -> ConfigTable?
    {
        var fields = document
        for (index, key) in path.enumerated() {
            guard let value = fields[key] else { return nil }
            guard index == path.count - 1 else {
                guard case .table(let inner) = value else { return nil }
                fields = inner
                continue
            }
            return reader.table(value, at: path)
        }
        return fields
    }

    /// The preferences Malum always sets.
    var alwaysPreferences: [AppPreference] {
        var reading = Reading()
        for item in always {
            reading.add(.set(item.value), to: item.target, at: [], document: PlistText.document)
        }
        return reading.preferences.map(\.preference)
    }

    /// The preferences in `wanted`, each once, with an error in `reader` for each one two keys set
    /// to different values, or one Malum always sets.
    func merged(_ wanted: [Wanted], _ reader: inout TableReader) -> [AppPreference] {
        let kept = once(
            wanted, id: { $0.preference.domain + "\n" + $0.preference.key }, path: \.path,
            same: { $0.preference.value == $1.preference.value }, &reader)
        return kept.map(\.preference)
    }

    /// The tables the app's files are written from, holding `values`, each once, with an error in
    /// `reader` for each key two settings set to different values, or one Malum always sets, put in
    /// the app's form by `arrange` when the catalog has it.
    func tables(_ values: [FileValue], _ reader: inout TableReader) -> ConfigTable {
        let kept = once(
            values, id: { TableReader.dotted($0.target) }, path: \.path, same: { $0.value == $1.value },
            &reader)
        var tables: ConfigTable = [:]
        for value in kept {
            tables.set(value.value, at: value.target)
        }
        return arrange?(tables, &reader) ?? tables
    }

    /// `items`, each `id` once, with an error in `reader` for each one that asks for something
    /// else than an earlier one with the same `id`.
    private func once<Item>(
        _ items: [Item], id: (Item) -> String, path: (Item) -> [String], same: (Item, Item) -> Bool,
        _ reader: inout TableReader
    ) -> [Item] {
        var first: [String: Item] = [:]
        var kept: [Item] = []
        for item in items {
            guard let earlier = first[id(item)] else {
                first[id(item)] = item
                kept.append(item)
                continue
            }
            guard !same(earlier, item) else { continue }
            let dotted = TableReader.dotted(path(item))
            let earlierPath = path(earlier)
            let text: MessageText =
                earlierPath.isEmpty ? alwaysConflict(dotted) : .setTwice(dotted, TableReader.dotted(earlierPath))
            reader.add(.error, at: path(item), text)
        }
        return kept
    }
}

extension Catalog.Reading {
    /// Adds what `write` does to `target`, asked for by the key `path`, with each preference value
    /// written by `document`. A key in an app's file that's removed or left is left out.
    fileprivate mutating func add(
        _ write: CatalogSetting.Write, to target: CatalogSetting.Target, at path: [String],
        document: (ConfigValue) -> String?
    ) {
        let setting = path.isEmpty ? nil : TableReader.dotted(path)
        switch (target, write) {
        case (_, .leave):
            return
        case (.preference(let domain, let key), .set(let given)):
            guard let value = document(given) else { return }
            preferences.append(
                Catalog.Wanted(
                    path: path, preference: AppPreference(domain: domain, key: key, value: value, setting: setting)))
        case (.preference(let domain, let key), .remove):
            preferences.append(
                Catalog.Wanted(
                    path: path, preference: AppPreference(domain: domain, key: key, value: nil, setting: setting)))
        case (.file(let keys), .set(let given)):
            files.append(Catalog.FileValue(path: path, target: keys, value: given))
        case (.fileKeys(let table, let value), .set(let given)):
            for key in TableReader.texts(given) ?? [] {
                files.append(Catalog.FileValue(path: path, target: table + [key], value: value))
            }
        case (.file, .remove), (.fileKeys, .remove):
            return
        }
    }
}

extension CatalogSetting.Target {
    /// The target once for each of `items`, with `item` in its path filled in by it, or the target
    /// as it is when its path doesn't hold `item`.
    fileprivate func filled(_ item: String?, with items: [String]) -> [Self] {
        guard let item, case .file(let keys) = self, keys.contains(item) else { return [self] }
        return items.map { each in .file(keys.map { $0 == item ? each : $0 }) }
    }
}
