import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppWindowsStateTests {
    private let window = WindowLayout.windowRole
    private let desktop = "AXScrollArea"

    /// The state of an app with `windows`, each a role and whether it's minimised.
    private func state(_ windows: (role: String?, isMinimized: Bool)...) -> AppWindowsState {
        AppWindowsState(windows: windows)
    }

    @Test func noElementsIsNoWindows() {
        #expect(state() == .noWindows)
    }

    @Test func onlyFindersDesktopIsNoWindows() {
        #expect(state((desktop, false)) == .noWindows)
    }

    @Test func windowBesideDesktopIsSome() {
        #expect(state((desktop, false), (window, false)) == .some)
    }

    @Test func everyWindowMinimizedIsOnlyMinimized() {
        #expect(state((desktop, false), (window, true)) == .onlyMinimized)
    }

    @Test func oneWindowInViewIsSome() {
        #expect(state((window, true), (window, false)) == .some)
    }

    @Test func windowWithoutRoleYetCounts() {
        #expect(state((nil, false)) == .some)
    }
}
