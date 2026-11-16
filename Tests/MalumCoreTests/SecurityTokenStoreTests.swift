import Synchronization
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SecurityTokenStoreTests {
    static let service = "test.service"
    static let account = "joris@nas.local"

    /// A keychain in memory that answers `security` the way the real one does.
    final class Keychain: Sendable {
        let password = Mutex<String?>(nil)
        let failure: CommandResult?

        init(_ password: String? = nil, failure: CommandResult? = nil) {
            self.password.withLock { $0 = password }
            self.failure = failure
        }

        func answer(_ command: Command) -> CommandResult {
            if let failure { return failure }
            if let input = command.input {
                password.withLock { $0 = Self.password(in: input) }
                return CommandResult(status: 0)
            }
            let missing = CommandResult(status: Security.notFoundStatus, errors: "could not be found\n")
            guard let stored = password.withLock({ $0 }) else { return missing }
            switch command.arguments.first {
            case "delete-generic-password":
                password.withLock { $0 = nil }
                return CommandResult(status: 0)
            default:
                return CommandResult(
                    status: 0, output: command.arguments.contains("-w") ? "\(stored)\n" : "attributes\n")
            }
        }

        /// The password in the hex after `-X` in a line `security -i` reads.
        private static func password(in line: String) -> String? {
            guard let hex = line.split(separator: " ").last?.trimmingCharacters(in: .newlines) else { return nil }
            var bytes: [UInt8] = []
            var index = hex.startIndex
            while index < hex.endIndex {
                let next = hex.index(index, offsetBy: 2)
                guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
                bytes.append(byte)
                index = next
            }
            return String(bytes: bytes, encoding: .utf8)
        }
    }

    private func store(_ keychain: Keychain) -> (SecurityTokenStore, FakeRunner) {
        let runner = FakeRunner { keychain.answer($0) }
        return (SecurityTokenStore(runner: runner, service: Self.service, account: Self.account), runner)
    }

    @Test func savedPasswordReadsBackWithoutItsLineBreak() async throws {
        let keychain = Keychain()
        let (store, _) = store(keychain)
        try await store.save("pass word")
        #expect(try await store.token() == "pass word")
        #expect(try await store.isStored())
    }

    @Test func passwordNeverShowsInTheArguments() async throws {
        let (store, runner) = store(Keychain())
        try await store.save("hunter2")
        #expect(runner.commands.allSatisfy { !$0.arguments.joined().contains("hunter2") })
        #expect(runner.commands.first == Security.savePassword("hunter2", service: Self.service, account: Self.account))
    }

    @Test func missingItemIsNilAndNotStored() async throws {
        let (store, _) = store(Keychain())
        #expect(try await store.token() == nil)
        #expect(try await store.isStored() == false)
        #expect(try await store.remove() == false)
    }

    @Test func removeDeletesTheItem() async throws {
        let keychain = Keychain("old")
        let (store, _) = store(keychain)
        #expect(try await store.remove())
        #expect(keychain.password.withLock { $0 } == nil)
    }

    @Test func otherFailureIsThrown() async {
        let (store, _) = store(
            Keychain(failure: CommandResult(status: 51, errors: "User interaction is not allowed.\n")))
        await #expect(throws: TokenStoreError.keychain(reason: "User interaction is not allowed.")) {
            try await store.token()
        }
    }

    @Test func saveThatDidntStickIsThrown() async {
        let runner = FakeRunner { command in
            command.input == nil ? CommandResult(status: 0, output: "old\n") : CommandResult(status: 0)
        }
        let store = SecurityTokenStore(runner: runner, service: Self.service, account: Self.account)
        await #expect(throws: TokenStoreError.unsaved) { try await store.save("new") }
    }
}
