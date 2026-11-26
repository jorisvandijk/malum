import Testing

@testable import MalumCore

/// The value kinds batch 4 added: numbers with a unit, text, missing text colours and shortcuts
/// written as keys.
extension CatalogTests {
    /// What `kind` writes for `value` to a setting's one target, or nil when it takes no such value.
    private func one(_ kind: CatalogValue, _ value: ConfigValue) -> ConfigValue? {
        guard case .set(let written)? = kind.writes(for: value, targets: 1, home: "/Users/test")?.first else {
            return nil
        }
        return written
    }

    @Test func numbersWithAUnitTakeWholeAndDecimalNumbers() {
        let size = CatalogValue.number(.pt, 6...100, decimal: false)
        #expect(one(size, .integer(14)) == .integer(14))
        #expect(one(size, .float(13.5)) == .float(13.5))
        #expect(one(.number(.pt, 6...100, decimal: true), .integer(14)) == .float(14))
        #expect(one(size, .integer(5)) == nil)
        #expect(one(size, .string("14")) == nil)
        #expect(size.description == "a number of points from 6 to 100")
        #expect(NumberUnit.lines.suffix == "_lines")
    }

    @Test func textIsWrittenInItsForm() {
        #expect(one(.text(.plain), .string("Dracula Theme")) == .string("Dracula Theme"))
        #expect(one(.text(.plain), .string("")) == nil)
        #expect(one(.text(.plain), .integer(1)) == nil)
        #expect(
            one(.text(.nested(["customFont", "name"])), .string("Menlo"))
                == .table(["customFont": .table(["name": .string("Menlo")])]))
        #expect(one(.text(.fontList(fallback: "monospace")), .string("Menlo")) == .string("'Menlo', monospace"))
        #expect(one(.text(.fontList(fallback: nil)), .string("Menlo")) == .string("'Menlo'"))
    }

    @Test func aColorPairWithUnsetTakesNoTextColour() {
        let pair = CatalogValue.colorPair(join: ",", unset: "default")
        #expect(one(pair, .table(["bg": .string("#282a36")])) == .string("default,#282a36"))
        #expect(one(pair, .table(["fg": .string("#f8f8f2")])) == .string("#f8f8f2"))
        #expect(one(pair, .table(["style": .string("bold")])) == nil)
        #expect(one(pair, .table(["fg": .string("#F8F8F2")])) == nil)
    }

    @Test func textShortcutsRenameKeysAndWholeShortcuts() throws {
        let style = ShortcutStyle.text(
            names: [.ctrl: "Ctrl", .option: "Alt"], fn: nil, joiner: "-", keys: ["slash": "/"],
            whole: ["ctrl+slash": "CtrlUnderscore"])
        #expect(style.value(try #require(Shortcut("option+slash"))) == .string("Alt-/"))
        #expect(style.value(try #require(Shortcut("ctrl+slash"))) == .string("CtrlUnderscore"))
        #expect(style.value(try #require(Shortcut("ctrl+option+k"))) == .string("Ctrl-Alt-k"))
        #expect(style.value(try #require(Shortcut("cmd+s"))) == nil)
    }

    @Test func shortcutKeysTakeOneOrAListAndBecomeKeys() throws {
        let kind = CatalogValue.shortcutKeys(.shared)
        #expect(one(kind, .string("option+k")) == .array([.string("option+k")]))
        #expect(one(kind, .array([.string("ctrl+k"), .string("f5")])) == .array([.string("ctrl+k"), .string("f5")]))
        #expect(one(kind, .array([])) == nil)
        #expect(one(kind, .array([.string("ctrl+k"), .string("nope")])) == nil)

        let catalog = Catalog(
            file: "apps/sample.toml",
            tables: [
                CatalogTable(
                    name: "shortcuts", about: "",
                    settings: [
                        CatalogSetting(
                            "comment", "", kind, [.fileKeys(table: ["bindings"], value: .string("comment"))]),
                        CatalogSetting("save", "", kind, [.fileKeys(table: ["bindings"], value: .string("save"))]),
                    ])
            ])
        var reader = try TableReader(
            "[shortcuts]\ncomment = [\"ctrl+k\", \"option+k\"]\nsave = \"ctrl+k\"\n", file: "apps/sample.toml")
        let tables = catalog.tables(catalog.read(&reader, home: "/Users/test").files, &reader)
        #expect(tables == ["bindings": .table(["ctrl+k": .string("comment"), "option+k": .string("comment")])])
        #expect(reader.problems.map(\.text) == [.setTwice("shortcuts.save", "shortcuts.comment")])
    }
}
