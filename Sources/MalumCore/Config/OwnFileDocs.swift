/// The references of the files in dots whose settings Malum acts on itself, such as
/// `keyboard.toml`, one page per file, made from its catalog so it always matches what Malum reads.
public enum OwnFileDocs {
    /// One file's page.
    private struct Page {
        /// Where the page goes, from the top of the repository.
        let path: String
        /// The file's catalog.
        let catalog: Catalog
        /// The hand-written page about what the file is for, such as `keyboard.md`.
        let guide: String
        /// That page's title, such as "keyboard".
        let guideTitle: String
    }

    /// Every page.
    private static let all = [
        Page(
            path: "docs/keyboard-settings.md", catalog: KeyboardCatalog.catalog, guide: "keyboard.md",
            guideTitle: "keyboard"),
        Page(
            path: "docs/window-manager-settings.md", catalog: WindowManagerConfig.catalog,
            guide: "window-manager.md", guideTitle: "window manager"),
        Page(
            path: "docs/web-apps-settings.md", catalog: WebAppList.catalog, guide: "system-config.md#web-apps",
            guideTitle: "web apps"),
    ]

    /// Each page, by its path from the top of the repository.
    public static func pages() -> [String: String] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.path, page($0)) })
    }

    /// The text of `page`.
    private static func page(_ page: Page) -> String {
        let file = page.catalog.file
        let header = """
            <!-- Made from the \(file) catalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

            # \(file) reference

            Every table and setting `\(file)` takes. A setting you leave out takes its default. A name a \
            table doesn't take gets a warning. See [\(page.guideTitle)](\(page.guide)) for how it works.

            """
        return header + CatalogDocs.sections(of: page.catalog) { _ in "" }
    }
}
