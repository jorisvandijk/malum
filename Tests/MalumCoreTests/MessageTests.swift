import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct MessageTests {
    @Test func descriptionStartsWithLowercaseTag() {
        #expect(
            Message(.warn, "couldn't read malum.toml: no such file").description
                == "[warn] couldn't read malum.toml: no such file")
    }
}
