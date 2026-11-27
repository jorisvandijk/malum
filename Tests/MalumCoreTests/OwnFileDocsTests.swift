import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct OwnFileDocsTests {
    @Test func eachFileGetsAPageFromItsCatalog() throws {
        let pages = OwnFileDocs.pages()
        #expect(
            Set(pages.keys) == [
                "docs/keyboard-settings.md", "docs/window-manager-settings.md", "docs/web-apps-settings.md",
            ])
        let keyboard = try #require(pages["docs/keyboard-settings.md"])
        #expect(keyboard.hasPrefix("<!-- Made from the keyboard.toml catalog by `swift run MalumDocs`."))
        #expect(keyboard.contains("# keyboard.toml reference"))
        #expect(keyboard.contains("See [keyboard](keyboard.md) for how it works."))
        #expect(keyboard.hasSuffix(CatalogDocs.sections(of: KeyboardCatalog.catalog) { _ in "" }))
    }
}
