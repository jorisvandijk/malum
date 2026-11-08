import Foundation
import MalumCore

// Writes the config reference in docs/ from the modules' schemas. Run it from the top of the
// repository after changing a schema: `swift run MalumDocs`. CI fails when the page is out of date.

/// Each module's schema, by the module's id.
let schemas = ConfigSchemas.all(modules: Modules.all())
/// Where the tool reports what it did.
let terminal = Terminal()
/// The page, from the folder the tool runs in.
let path = FileManager.default.currentDirectoryPath + "/" + ConfigDocs.path

do {
    try LocalFileSystem().write(ConfigDocs.page(for: schemas), to: path)
    terminal.report(.wrote(ConfigDocs.path))
} catch {
    terminal.report(.failed(error))
    exit(EXIT_FAILURE)
}
