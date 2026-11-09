@testable import MalumCore

/// A folder watch that keeps the folders it watches and changes when told.
@MainActor
final class FakeFolderWatch: FolderWatch {
    /// The folders watched, empty when stopped.
    private(set) var folders: [String] = []
    /// What to call on a change.
    private var onChange: (@MainActor () -> Void)?

    func start(_ folders: [String], onChange: @escaping @MainActor () -> Void) {
        self.folders = folders
        self.onChange = onChange
    }

    func stop() {
        folders = []
        onChange = nil
    }

    /// Calls back as a real change would.
    func change() {
        onChange?()
    }
}
