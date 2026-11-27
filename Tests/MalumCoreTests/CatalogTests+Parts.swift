import Testing

@testable import MalumCore

/// The value kinds and tables batch 5 added: counts, lists of parts, apps, colour pairs written to
/// two keys, paths with text after them, parts of tables and tables of entries.
extension CatalogTests {
    /// What `kind` writes for `value` to a setting's targets, or nil when it takes no such value.
    private func written(_ kind: CatalogValue, _ value: ConfigValue, targets: Int = 1) -> [ConfigValue]? {
        kind.writes(for: value, targets: targets, home: "/Users/test")?.compactMap { write in
            guard case .set(let value) = write else { return nil }
            return value
        }
    }

    @Test func countsTakeWholeNumbersInTheirRange() {
        #expect(written(.count(1...10), .integer(10)) == [.integer(10)])
        #expect(written(.count(1...10), .integer(0)) == nil)
        #expect(written(.count(1...10), .float(2.5)) == nil)
        #expect(CatalogValue.count(1...Int.max).description == "a whole number, 1 or more")
    }

    @Test func partsAreJoinedInTheirOrder() {
        let parts = CatalogValue.parts([CatalogValue.Part("day", "%d"), CatalogValue.Part("month", "%b")], join: " ")
        #expect(written(parts, .array([.string("month"), .string("day")])) == [.string("%b %d")])
        #expect(written(parts, .array([])) == nil)
        #expect(written(parts, .array([.string("year")])) == nil)
        #expect(written(parts, .string("day")) == nil)
        #expect(parts.description == "a list of at least one of \"day\" or \"month\"")
    }

    @Test func partsWithANoneWordTakeAnEmptyList() {
        let parts = CatalogValue.parts([CatalogValue.Part("history", "history")], join: ",", none: "none")
        #expect(written(parts, .array([])) == [.string("none")])
        #expect(written(parts, .array([.string("history")])) == [.string("history")])
        #expect(parts.description == "a list of any of \"history\"")
    }

    @Test func aListOfPartsIsWrittenAsAListAndMayRepeatAWord() {
        let parts = CatalogValue.partList([
            CatalogValue.Part("space", "spring"), CatalogValue.Part("back", "back-button"),
        ])
        #expect(
            written(parts, .array([.string("space"), .string("back"), .string("space")]))
                == [.array([.string("spring"), .string("back-button"), .string("spring")])])
        #expect(written(parts, .array([])) == nil)
        #expect(written(parts, .array([.string("home")])) == nil)
    }

    @Test func anAppIsWrittenByItsBundleIDInsideItsCommand() {
        let app = CatalogValue.app(before: "open -b ", after: " %u")
        #expect(written(app, .string("net.librewolf.librewolf")) == [.string("open -b net.librewolf.librewolf %u")])
        #expect(written(app, .string("open -a 'LibreWolf'")) == nil)
    }

    @Test func aColourPairForTwoKeysWritesEachColour() {
        let pair = ConfigValue.table(["fg": .string("#f8f8f2"), "bg": .string("#282a36")])
        #expect(written(.colorPairKeys, pair, targets: 2) == [.string("#f8f8f2"), .string("#282a36")])
        #expect(written(.colorPairKeys, .table(["fg": .string("#f8f8f2")]), targets: 2) == nil)
        #expect(
            written(
                .colorPairKeys, .table(["fg": .string("#f8f8f2"), "bg": .string("#282a36"), "style": .string("bold")]))
                == nil)
        #expect(written(.colorPairKeys, .string("#f8f8f2,#282a36"), targets: 2) == nil)
    }

    @Test func aPathCanHaveTextAfterIt() {
        #expect(written(.path(then: "/%n"), .string("$HOME/Downloads")) == [.string("/Users/test/Downloads/%n")])
        #expect(written(.list(.hosts), .array([.string("github.com")])) == [.array([.string("github.com")])])
        #expect(written(.list(.hosts), .array([])) == nil)
    }

    @Test func aPartOfATableIsReadInsideIt() throws {
        let catalog = Catalog(
            file: "apps/test.toml",
            tables: [
                CatalogTable(
                    name: "colors", about: "Colours.",
                    settings: [CatalogSetting("cursor", "The cursor.", .color, [.file(["theme", "cursor"])])]),
                CatalogTable(
                    name: "colors.normal", about: "Terminal colours.",
                    settings: [CatalogSetting("red", "Red.", .color, [.file(["theme", "color1"])])]),
            ])
        var reader = try TableReader(
            "[colors]\ncursor = \"#ffffff\"\nblue = \"#0000ff\"\n\n[colors.normal]\nred = \"#ff0000\"\n",
            file: "apps/test.toml")
        let files = catalog.read(&reader, home: "/Users/test").files
        #expect(files.map(\.target) == [["theme", "cursor"], ["theme", "color1"]])
        #expect(reader.problems.map { Message($0.level, $0.text) } == [Message(.warn, "unknown setting colors.blue")])
        #expect(catalog.topTables == ["colors"])
        #expect(catalog.parts(of: ["colors"]) == ["normal"])
    }
}
