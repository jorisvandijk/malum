import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PlistMatchTests {
    /// A Dock app as `macos.toml` asks for it.
    private let wanted = PlistText.document(.array([.table(["tile-type": .string("file-tile")])])) ?? ""
    /// The same app as the Dock keeps it, with keys of its own.
    private let current: Any = [["tile-type": "file-tile", "GUID": 42] as [String: Any]]

    @Test func containingIgnoresKeysMacOSAdds() {
        #expect(PlistMatch.matches(wanted, current, rule: .containing))
        #expect(!PlistMatch.matches(wanted, current, rule: .exact))
    }

    @Test func containingStillNeedsEveryValue() {
        let other: Any = [["tile-type": "directory-tile", "GUID": 42] as [String: Any]]
        #expect(!PlistMatch.matches(wanted, other, rule: .containing))
        #expect(!PlistMatch.matches(wanted, [Any](), rule: .containing))
        #expect(!PlistMatch.matches(wanted, nil, rule: .containing))
    }

    @Test func plainValuesMatchExactly() {
        let flag = PlistText.document(.boolean(true)) ?? ""
        #expect(PlistMatch.matches(flag, true, rule: .exact))
        #expect(PlistMatch.matches(flag, true, rule: .containing))
        #expect(!PlistMatch.matches(flag, false, rule: .containing))
    }
}
