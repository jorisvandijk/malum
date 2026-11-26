import Foundation
import MalumCore

// Writes the config references in docs/: the modules' settings from their schemas, and the macOS
// settings from the catalog. Run it from the top of the repository after changing a schema or the
// catalog: `swift run MalumDocs`. CI fails when a page is out of date.

/// Each module's schema, by the module's id.
let schemas = ConfigSchemas.all
/// Where the tool reports what it did.
let terminal = Terminal()
/// The folder the tool runs in, the top of the repository.
let top = FileManager.default.currentDirectoryPath + "/"
/// Each page, by its path from the top of the repository.
let pages = [ConfigDocs.path: ConfigDocs.page(for: schemas), MacOSDocs.path: MacOSDocs.page()]

do {
    for (path, page) in pages.sorted(by: { $0.key < $1.key }) {
        try LocalFileSystem().write(page, to: top + path)
        terminal.report(.wrote(path))
    }
} catch {
    terminal.report(.failed(error))
    exit(EXIT_FAILURE)
}
