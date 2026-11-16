/// `malum permissions` in the app: opens System Settings at each permission the switched-on modules
/// wait for, one at a time, and moves on once it's granted.
///
/// macOS lets only the user switch a permission on, so this is as close to one step as it gets. A
/// permission macOS can't tell about is skipped, since there's no way to see it granted; macOS asks
/// for those itself the first time a module needs one.
@MainActor
public final class PermissionWalk {
    /// The action name `malum permissions` asks the running app for.
    public static let actionName = "permissions"
    /// Seconds between checks while a page is open.
    public static let pauseSeconds = 1

    /// Tells which permissions Malum has.
    private let check: any PermissionCheck
    /// Opens System Settings where `Permission` is granted, listing Malum there when macOS lets it.
    private let open: (Permission) -> Void
    /// Waits a moment between checks. Throws when the walk is cancelled.
    private let pause: () async throws -> Void
    /// Says how the walk goes.
    private let report: (Message) -> Void
    /// The walk that runs, so a new one replaces it.
    private var current: Task<Void, Never>?

    /// Creates the walk, which checks with `check`, opens pages with `open`, waits with `pause`
    /// between checks (a second by default) and reports to `report`.
    public init(
        check: any PermissionCheck, open: @escaping (Permission) -> Void,
        pause: @escaping () async throws -> Void = { try await Task.sleep(for: .seconds(pauseSeconds)) },
        report: @escaping (Message) -> Void
    ) {
        self.check = check
        self.open = open
        self.pause = pause
        self.report = report
    }

    /// Walks through `waiting`, the permissions each waiting module misses by its id, replacing a
    /// walk that still runs.
    public func start(waiting: [String: Set<Permission>]) {
        current?.cancel()
        let needed = Permission.allCases.filter { permission in
            waiting.values.contains { $0.contains(permission) } && check.state(of: permission) == .missing
        }
        current = Task { [weak self] in await self?.walk(needed) }
    }

    /// Opens each of `needed` in turn and waits until it's granted. Says when all are.
    func walk(_ needed: [Permission]) async {
        for (index, permission) in needed.enumerated() {
            report(.grantNext(permission, number: index + 1, of: needed.count))
            open(permission)
            do {
                while check.state(of: permission) == .missing { try await pause() }
            } catch {
                return  // A new walk took over.
            }
        }
        report(.everyPermissionGranted)
    }
}
