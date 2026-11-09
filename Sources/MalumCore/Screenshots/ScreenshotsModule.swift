import Foundation
import Observation

/// Screenshots: its action freezes the screen under the mouse in an overlay to crop and draw on.
/// Saving writes the plain shot, and the annotated one when something was drawn, to the folder,
/// and puts the last of them on the clipboard.
@Observable
@MainActor
final class ScreenshotsModule: Module {
    /// The module's id.
    let id = ScreenshotsConfig.module
    /// Freezing the screen needs Screen Recording.
    let permissions: Set<Permission> = [.screenRecording]
    /// Its settings.
    var schema: ConfigSchema { ScreenshotsConfig.schema }
    /// It offers one action, `screenshot`.
    var hotkeys: HotkeyOffer { HotkeyOffer(actions: [ScreenshotsConfig.action]) }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through.
    @ObservationIgnored private let system: ScreenshotsSystem
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The time now, which tests set.
    @ObservationIgnored private let now: () -> Date
    /// The settings last given.
    @ObservationIgnored private var config = ScreenshotsConfig()
    /// The shot in progress, from freeze to save, which tests wait for.
    @ObservationIgnored private(set) var shot: Task<Void, Never>?

    /// Creates the module, off.
    init(system: ScreenshotsSystem, log: Log, now: @escaping () -> Date = Date.init) {
        self.system = system
        self.log = log.module(ScreenshotsConfig.module)
        self.now = now
    }

    /// Nothing to undo: shots change nothing that outlives Malum.
    func cleanUp() async throws {}

    /// Takes new settings.
    func apply(_ settings: ModuleSettings) {
        config = ScreenshotsConfig.read(settings.table) { _, _ in }
    }

    /// Nothing runs between shots.
    func start() async throws {
        status = .running
    }

    /// Lets a shot in progress finish; nothing else runs.
    func stop() async {
        status = .off
    }

    /// Takes a screenshot, unless one is open already.
    func perform(_ action: KeyAction) {
        guard action == .module(ScreenshotsConfig.action), shot == nil else { return }
        shot = Task { [weak self] in
            await self?.take()
            self?.shot = nil
        }
    }

    /// Freezes the screen, lets the user edit the shot, and saves it unless cancelled.
    private func take() async {
        let frozen: any FrozenScreen
        do {
            frozen = try await system.capture.freeze()
        } catch {
            log.report(.failed(error))
            return
        }
        guard let edits = await system.overlay.edit(frozen, quickColors: config.colors) else { return }
        do {
            try save(edits, of: frozen)
        } catch {
            log.report(.failed(error))
        }
    }

    /// Writes the plain shot and, when something was drawn, the annotated one, and puts the last
    /// written on the clipboard.
    private func save(_ edits: ScreenshotEdits, of frozen: any FrozenScreen) throws {
        let folder = config.folderPath(system.paths)
        try system.files.createDirectory(folder)
        let files = ScreenshotFiles.next(at: now(), in: folder) { system.files.item(at: $0) != nil }
        var copied = try frozen.png(crop: edits.crop, annotations: [])
        try system.files.write(copied, to: files.plain)
        log.report(.savedScreenshot(files.plain))
        if edits.isAnnotated {
            copied = try frozen.png(crop: edits.crop, annotations: edits.annotations)
            try system.files.write(copied, to: files.annotated)
            log.report(.savedScreenshot(files.annotated))
        }
        let entry = ClipEntry(id: UUID().uuidString, kind: .image, date: now())
        guard system.clipboard.put(entry, image: copied) else {
            log.report(.couldntCopyScreenshot)
            return
        }
    }
}
