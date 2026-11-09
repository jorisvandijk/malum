import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SambaPasswordCommandTests {
    private let paths = Paths(home: "/Users/test")
    private let pointer = "/Users/test/.config/malum/config"
    private let config = "/Users/test/dots/malum.toml"
    private let samba = "/Users/test/dots/samba.toml"
    private let nas = SambaServer(name: "nas", host: "nas.local", user: "joris", shares: ["media"])
    private let servers = """
        [[server]]
        name = "nas"
        host = "nas.local"
        user = "joris"
        shares = ["media"]

        [[server]]
        name = "pi"
        host = "pi"
        user = "pi"
        shares = ["files"]
        """

    /// The command reading `texts`, with dots at `/Users/test/dots`, keeping passwords in `store`.
    private func command(_ texts: [String: String], store: FakeTokenStore = FakeTokenStore()) -> SambaPasswordCommand {
        let files = FakeFileSystem(texts: [pointer: "/Users/test/dots\n"].merging(texts) { first, _ in first })
        return SambaPasswordCommand(files: files, paths: paths) { _ in store }
    }

    /// What finding `name` reports, and the server found.
    private func find(_ name: String, in command: SambaPasswordCommand) -> (SambaServer?, [Message]) {
        var messages: [Message] = []
        let server = command.server(named: name) { messages.append($0) }
        return (server, messages)
    }

    @Test func serverIsFoundByName() {
        let (server, messages) = find("nas", in: command([config: "", samba: servers]))
        #expect(server == nas)
        #expect(messages.isEmpty)
    }

    @Test func unknownServerNamesTheOnesThereAre() {
        let (server, messages) = find("box", in: command([config: "", samba: servers]))
        #expect(server == nil)
        #expect(messages == [Message(.error, "samba.toml has no server called box, only nas, pi")])
    }

    @Test func noServersSaysToAddOne() {
        let (server, messages) = find("nas", in: command([config: ""]))
        #expect(server == nil)
        #expect(messages == [.noSambaSettings])
    }

    @Test func brokenSettingsShowTheirProblems() {
        let (server, messages) = find("nas", in: command([config: "", samba: "server = 3\n"]))
        #expect(server == nil)
        #expect(
            messages == [
                ConfigProblem(.error, file: "samba.toml", line: 1, .shouldBe("server", SettingKind.tables)).message,
                .noSambaSettings,
            ])
    }

    @Test func passwordIsSavedForTheServer() {
        let store = FakeTokenStore()
        let message = command([:], store: store).save("hunter2", for: nas)
        #expect(message == Message(.info, "saved the password for joris@nas.local in the login keychain"))
        #expect(store.current == "hunter2")
    }

    @Test func emptyPasswordIsNotSaved() {
        let store = FakeTokenStore("old")
        #expect(command([:], store: store).save("", for: nas) == .noPasswordEntered)
        #expect(command([:], store: store).save(nil, for: nas) == .noPasswordEntered)
        #expect(store.current == "old")
    }

    @Test func keychainFailureIsReported() {
        let store = FakeTokenStore(failure: .keychain(status: -25_308, reason: "denied"))
        let message = command([:], store: store).save("hunter2", for: nas)
        #expect(
            message
                == Message(
                    .error, "couldn't save the password for joris@nas.local: the login keychain answered denied"))
    }

    @Test func promptNamesTheAccount() {
        #expect(SambaPasswordCommand.prompt(for: nas) == "Password for joris@nas.local: ")
    }
}
