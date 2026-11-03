import Dispatch
import Foundation
import MalumCore

/// Calls back on the main actor when `malum.toml` may have changed.
///
/// Editors save in one of two ways, so it watches both: writing into the file itself, which the
/// watch on the file sees, and writing a new file and renaming it over the old one, which the
/// watch on the folder sees. After a rename the file watch still points at the replaced file, so
/// it's attached again after every change. A missing file is seen by the folder watch when it
/// appears.
@MainActor
public final class ConfigWatcher {
    /// A watch on one file or folder.
    private typealias Source = any DispatchSourceFileSystemObject

    /// How many milliseconds a save takes to settle, since editors touch the file and the folder
    /// several times.
    private static let settleMilliseconds = 200

    /// The file being watched.
    public let path: String
    /// What to call once a change has settled.
    private let onChange: @MainActor () -> Void
    /// Waits for a save to settle.
    private let debouncer = Debouncer(delay: .milliseconds(settleMilliseconds))
    /// The watch on the folder that holds the file.
    private var folderSource: Source?
    /// The watch on the file itself.
    private var fileSource: Source?

    /// Starts watching `path`. `onChange` runs on the main actor once each change has settled.
    public init(path: String, onChange: @escaping @MainActor () -> Void) {
        self.path = path
        self.onChange = onChange
        folderSource = watch(folder, events: [.write, .rename, .delete])
        watchFile()
    }

    /// The folder that holds the file.
    public var folder: String { URL(fileURLWithPath: path).deletingLastPathComponent().path }

    /// Whether the folder is watched. Without it, only `malum reload` picks up changes.
    public var isWatching: Bool { folderSource != nil }

    /// Stops watching.
    public func stop() {
        debouncer.cancel()
        folderSource?.cancel()
        fileSource?.cancel()
        folderSource = nil
        fileSource = nil
    }

    /// Watches the file again, which may now be a different file at the same path.
    private func watchFile() {
        fileSource?.cancel()
        fileSource = watch(path, events: [.write, .extend, .rename, .delete])
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

    /// Waits for the save to settle, then watches the file again and calls back.
    private func changed() {
        debouncer.schedule { [weak self] in
            self?.watchFile()
            self?.onChange()
        }
    }
}
