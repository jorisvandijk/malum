import Foundation
import MalumCore

// Writes the config reference in docs/ from the modules' schemas. Run it from the top of the
// repository after changing a schema: `swift run MalumDocs`. CI fails when the page is out of date.

// TODO: one list of the modules' schemas, shared by the app and MalumDocs, once there are modules.
/// Each module's schema, by the module's id.
let schemas: [String: ConfigSchema] = [:]
/// Where the tool reports what it did.
let terminal = Terminal()
/// The page, from the folder the tool runs in.
let path = FileManager.default.currentDirectoryPath + "/" + ConfigDocs.path

do {
    try LocalFileSystem().write(ConfigDocs.page(for: schemas), to: path)
    terminal.report(Message(.info, "wrote \(ConfigDocs.path)"))
} catch {
    terminal.report(Message(.error, error.description))
    exit(EXIT_FAILURE)
}
