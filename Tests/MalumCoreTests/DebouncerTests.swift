import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct DebouncerTests {
    private let wait = Duration.milliseconds(300)

    @Test func burstOfCallsRunsOnlyTheLast() async throws {
        let debouncer = Debouncer(delay: .milliseconds(50))
        var runs: [Int] = []
        for call in 1...3 {
            debouncer.schedule { runs.append(call) }
        }
        try await Task.sleep(for: wait)
        #expect(runs == [3])
    }

    @Test func cancelDropsThePendingAction() async throws {
        let debouncer = Debouncer(delay: .milliseconds(50))
        var ran = false
        debouncer.schedule { ran = true }
        debouncer.cancel()
        try await Task.sleep(for: wait)
        #expect(!ran)
    }
}
