import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct OverridesTests {
    @Test func noOverridesAllowEveryEnabledModule() {
        #expect(Overrides().allowed(["launcher", "samba"]) == ["launcher", "samba"])
    }

    @Test func disabledModulesAreKeptOff() {
        #expect(Overrides(disabled: ["samba", "screenshots"]).allowed(["launcher", "samba"]) == ["launcher"])
    }

    @Test func safeModeKeepsEveryModuleOff() {
        #expect(Overrides(safeMode: .asked).allowed(["launcher", "samba"]).isEmpty)
    }
}
