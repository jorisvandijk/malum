import Foundation
import Observation

/// The clipboard history: records every copy, and its action opens the popup on the history, where
/// picking an entry puts it back on the clipboard and pastes it into the app below.
@Observable
@MainActor
final class ClipboardModule: Module {
    /// The history's folder in the state folder.
    private static let folderName = "history"

    /// The module's id, which is also its action in `keyboard.toml`.
    let id = ClipboardConfig.module
    /// Pasting sends cmd+V to another app, which needs Accessibility.
    let permissions: Set<Permission> = [.accessibility]
    /// Its settings.
    var schema: ConfigSchema { ClipboardConfig.schema }
    /// It offers one action, `clipboard`, which opens the popup on the history.
    var hotkeys: HotkeyOffer { HotkeyOffer(actions: [ClipboardConfig.module]) }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through.
    @ObservationIgnored private let system: ClipboardSystem
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The time now, which tests set.
    @ObservationIgnored private let now: () -> Date
    /// The settings last given.
    @ObservationIgnored private var config = ClipboardConfig()
    /// The history in the popup, while the module runs.
    @ObservationIgnored private var list: ClipboardList?

    /// Creates the module, off.
    init(system: ClipboardSystem, log: Log, now: @escaping () -> Date = Date.init) {
        self.system = system
        self.log = log.module(ClipboardConfig.module)
        self.now = now
    }

    /// Nothing to undo: the history changes nothing that outlives Malum.
    func cleanUp() async throws {}

    /// Takes new settings; a smaller size drops the oldest entries straight away.
    func apply(_ settings: ModuleSettings) {
        config = ClipboardConfig.read(settings.table)
        guard let history = list?.history else { return }
        save { try history.resize(to: config.size) }
    }

    /// Reads the history, shows it in the popup and starts recording copies.
    func start() async throws {
        status = .starting
        let history = ClipHistory(
            files: system.files, folder: system.state.path(of: Self.folderName), limit: config.size, now: now)
        save { try history.load() }
        let list = ClipboardList(
            history: history, now: now, onChoose: { [weak self] in self?.putBack($0) },
            onDelete: { [weak self] in self?.delete($0) })
        self.list = list
        system.popup.register(list, as: ClipboardConfig.module)
        system.clipboard.watch { [weak self] in self?.record($0) }
        check()
    }

    /// Stops recording and takes the history out of the popup.
    func stop() async {
        system.clipboard.stopWatching()
        system.popup.unregister(ClipboardConfig.module)
        list = nil
        status = .off
    }

    /// Shows whether macOS's Paste from Other Apps setting keeps Malum from the clipboard.
    func check() {
        guard list != nil else { return }
        let denied = system.clipboard.isDenied
        status = denied ? .degraded(reason: MessageText.clipboardDenied.description) : .running
    }

    /// Opens or closes the popup on the history.
    func perform(_ action: KeyAction) {
        guard action == .module(ClipboardConfig.module) else { return }
        system.popup.toggle(ClipboardConfig.module)
    }

    /// Keeps a copy, or logs one marked not to keep.
    private func record(_ seen: CopySeen) {
        guard let history = list?.history else { return }
        switch seen {
        case .copied(let copy):
            save { try history.add(copy) }
            system.popup.refresh(ClipboardConfig.module)
        case .skipped(let type):
            log.report(.skippedCopy(type))
        }
    }

    /// Puts `entry` back on the clipboard, makes it the newest and pastes it when set to.
    private func putBack(_ entry: ClipEntry) {
        guard let history = list?.history else { return }
        var image: Data?
        if entry.kind == .image {
            save { image = try system.files.data(at: history.imagePath(of: entry)) }
        }
        guard system.clipboard.put(entry, image: image) else {
            log.report(.couldntPutBack)
            return
        }
        save { try history.moveToTop(entry.id) }
        if config.pastes { system.clipboard.paste() }
    }

    /// Deletes `entry`, or every entry when nil.
    private func delete(_ entry: ClipEntry?) {
        guard let history = list?.history else { return }
        save {
            guard let entry else { return try history.clear() }
            try history.delete(entry.id)
        }
    }

    /// Runs `change` on the history, logging a failure; the history in memory goes on either way.
    private func save(_ change: () throws -> Void) {
        do {
            try change()
        } catch {
            log.report(.warning(error))
        }
    }
}
