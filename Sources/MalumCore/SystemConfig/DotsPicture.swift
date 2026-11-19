import Foundation

/// Finds a picture in a folder in dots by the name `malum.toml` gives it.
enum DotsPicture {
    /// The file in `folder` on `files` called `name`, or else the one whose name without its
    /// extension is `name`, or nil when there's none or `name` isn't a plain file name.
    static func file(named name: String, in folder: String, on files: any FileSystem) -> String? {
        guard Paths.isPlainName(name) else { return nil }
        let names = ((try? files.contents(of: folder)) ?? []).sorted()  // No folder: no pictures, reported.
        guard !names.contains(name) else { return name }
        return names.first { ($0 as NSString).deletingPathExtension == name }
    }
}
