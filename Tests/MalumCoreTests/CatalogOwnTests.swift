import Testing

@testable import MalumCore

/// Tables Malum acts on itself, and entries tables with optional settings and the entry's name.
@Suite(.timeLimit(.minutes(1)))
struct CatalogOwnTests {
    /// A made-up file with one setting and an entries table whose `note` is optional.
    private let catalog = Catalog(
        file: "sample.toml",
        tables: [
            CatalogTable(
                name: "window", about: "The window.",
                settings: [CatalogSetting("width_px", "The width.", .count(1...100), [.own("window", "width")])]),
            CatalogTable(
                name: "items", about: "Items.",
                entries: CatalogEntries(
                    keys: "a name",
                    settings: [
                        CatalogSetting(
                            "app", "The app.", .app(before: "", after: ""), [.own("items", CatalogEntries.entry, "app")]
                        ),
                        CatalogSetting("note", "A note.", .text(.plain), [.own("items", CatalogEntries.entry, "note")]),
                    ], optional: ["note"])),
        ])

    /// The tables `toml` gives and the problems found.
    private func own(_ toml: String) throws -> (table: ConfigTable, problems: [Message]) {
        var reader = try TableReader(toml, file: catalog.file)
        let table = catalog.own(&reader, home: "")
        return (table, reader.problems.map(\.message))
    }

    @Test func settingsAndEntriesGoWhereTheirTargetsSay() throws {
        let (table, problems) = try own(
            "[window]\nwidth_px = 40\n[items.one]\napp = \"com.example.one\"\nnote = \"hi\"\n[items.two]\napp = \"com.example.two\"\n"
        )
        #expect(problems.isEmpty)
        #expect(table.value(at: ["window", "width"]) == .integer(40))
        #expect(table.value(at: ["items", "one", "app"]) == .string("com.example.one"))
        #expect(table.value(at: ["items", "one", "note"]) == .string("hi"))
        #expect(table.value(at: ["items", "two", "app"]) == .string("com.example.two"))
        #expect(table.value(at: ["items", "two", "note"]) == nil)
    }

    @Test func onlyMissingSettingsThatArentOptionalAreErrors() throws {
        let (_, problems) = try own("[items.one]\nnote = \"hi\"\n")
        #expect(problems == [Message(.error, "sample.toml line 1: items.one needs app")])
    }

    @Test func docsNameTheOptionalSettings() {
        let docs = CatalogDocs.sections(of: catalog) { _ in "" }
        #expect(docs.contains("## `[items.<name>]`"))
        #expect(docs.contains("- Each one needs every setting below but `note`.\n"))
        #expect(!docs.contains("- Writes:"))
    }
}
