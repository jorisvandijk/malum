import Dispatch
import Foundation
import MalumCore

/// Calls back on the main actor when `malum.toml`, or a module's own file next to it, may have changed.
///
/// Editors save in one of two ways, so it watches both: writing into a file itself, which the
/// watch on the file sees, and writing a new file and renaming it over the old one, which the
/// watch on the folder sees. Emptying a file writes nothing and only changes its size, so the
/// file watches also listen for changed attributes. After a rename a file watch still points at the replaced file, so
/// the files are watched again after every change. A missing file is seen by the folder watch when it
/// appears.
@MainActor
public final class ConfigWatcher {
    /// A watch on one file or folder.
    private typealias Source = any DispatchSourceFileSystemObject

    /// How many milliseconds a save takes to settle, since editors touch the file and the folder
    /// several times.
    private static let settleMilliseconds = 200

    /// The folder that holds the files.
    public let folder: String
    /// The files being watched.
    public let paths: [String]
    /// What to call once a change has settled.
    private let onChange: @MainActor () -> Void
    /// Waits for a save to settle.
    private let debouncer = Debouncer(delay: .milliseconds(settleMilliseconds))
    /// The watch on the folder that holds the file.
    private var folderSource: Source?
    /// The watches on the files themselves.
    private var fileSources: [Source] = []

    /// Starts watching `paths`, the files in `folder`. `onChange` runs on the main actor once each
    /// change has settled.
    public init(folder: String, paths: [String], onChange: @escaping @MainActor () -> Void) {
        self.folder = folder
        self.paths = paths
        self.onChange = onChange
        folderSource = watch(folder, events: [.write, .rename, .delete])
        watchFiles()
    }

    /// Whether the folder is watched. Without it, only `malum reload` picks up changes.
    public var isWatching: Bool { folderSource != nil }

    /// Stops watching.
    public func stop() {
        debouncer.cancel()
        folderSource?.cancel()
        for source in fileSources { source.cancel() }
        folderSource = nil
        fileSources = []
    }

    /// Watches the files again, each of which may now be a different file at the same path. A
    /// missing file isn't watched.
    private func watchFiles() {
        for source in fileSources { source.cancel() }
        fileSources = paths.compactMap { watch($0, events: [.write, .extend, .attrib, .rename, .delete]) }
    }

    /// Watches `path` for `events`, or gives nil when it can't be opened, such as a missing file.
    private func watch(_ path: String, events: DispatchSource.FileSystemEvent) -> Source? {
        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: events, queue: .main)
        source.setEventHandler { [weak self] in MainActor.assumeIsolated { self?.changed() } }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        return source
    }

    /// Waits for the save to settle, then watches the files again and calls back.
    private func changed() {
        debouncer.schedule { [weak self] in
            self?.watchFiles()
            self?.onChange()
        }
    }
}
