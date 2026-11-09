import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SambaConfigTests {
    private let path = "/dots/malum.toml"
    private let file = "/dots/samba.toml"
    private let fileName = "samba.toml"
    private let module = SambaConfig.module

    /// The settings `text`, as `samba.toml`, give, read the way the module does.
    private func load(_ text: String) -> (config: SambaConfig?, problems: [ConfigProblem]) {
        var config = Config(schemas: [module: SambaConfig.schema])
        let report = config.load("", from: path, moduleFiles: [module: .text(path: file, text)])
        let table = config.moduleSettings[module]?.table
        return (table.map { SambaConfig.read($0) { _, _ in } }, report.problems)
    }

    @Test func nothingSetGivesNoServers() {
        let (config, problems) = load("")
        #expect(problems.isEmpty)
        #expect(config?.servers == [])
    }

    @Test func everyServerIsRead() {
        let text = """
            [[server]]
            name = "nas"
            host = "nas.local"
            user = "joris"
            shares = ["media", "backup"]

            [[server]]
            name = "pi"
            host = "192.168.1.20"
            user = "pi"
            shares = ["files"]
            """
        let (config, problems) = load(text)
        #expect(problems.isEmpty)
        #expect(
            config?.servers == [
                SambaServer(name: "nas", host: "nas.local", user: "joris", shares: ["media", "backup"]),
                SambaServer(name: "pi", host: "192.168.1.20", user: "pi", shares: ["files"]),
            ])
        #expect(config?.servers.first?.account == "joris@nas.local")
    }

    @Test func serversCanBeInConfig() {
        var config = Config(schemas: [module: SambaConfig.schema])
        let text = "[[samba.server]]\nname = \"nas\"\nhost = \"nas\"\nuser = \"me\"\nshares = [\"media\"]\n"
        let report = config.load(text, from: path)
        #expect(report.problems.isEmpty)
        let table = config.moduleSettings[module]?.table ?? [:]
        let read = SambaConfig.read(table) { _, _ in }
        #expect(read.servers == [SambaServer(name: "nas", host: "nas", user: "me", shares: ["media"])])
    }

    @Test func eachProblemIsAtItsLineAndTheModuleGetsNoSettings() {
        let text = """
            [[server]]
            name = "nas/2"
            host = "nas local"
            user = ""
            shares = []
            port = 445

            [[server]]
            name = "pi"
            host = "pi"
            user = "pi"
            shares = ["files", ".hidden"]
            """
        let (config, problems) = load(text)
        #expect(config == nil)
        #expect(
            problems == [
                ConfigProblem(.error, file: fileName, line: 2, .notPlainName("server.0.name")),
                ConfigProblem(.error, file: fileName, line: 3, .shouldBe("server.0.host", MessageText.sambaText)),
                ConfigProblem(.error, file: fileName, line: 4, .shouldBe("server.0.user", MessageText.sambaText)),
                ConfigProblem(.error, file: fileName, line: 5, .shouldBe("server.0.shares", MessageText.shareList)),
                ConfigProblem(.error, file: fileName, line: 6, .unknownKey("server.0.port", isTable: false)),
                ConfigProblem(.error, file: fileName, line: 12, .shouldBe("server.1.shares", MessageText.shareList)),
            ])
    }

    @Test func missingKeysAreReported() {
        let (config, problems) = load("[[server]]\nname = \"nas\"\n")
        #expect(config == nil)
        #expect(
            problems.map(\.text) == [
                .shouldBe("server.0.host", MessageText.sambaText), .shouldBe("server.0.user", MessageText.sambaText),
                .shouldBe("server.0.shares", MessageText.shareList),
            ])
    }

    @Test func aNameUsedTwiceIsAnError() {
        let server = "[[server]]\nname = \"nas\"\nhost = \"nas\"\nuser = \"me\"\nshares = [\"media\"]\n"
        let (config, problems) = load(server + "\n" + server)
        #expect(config == nil)
        #expect(problems == [ConfigProblem(.error, file: fileName, line: 8, .takenName("server.1.name"))])
    }

    @Test func serverMustBeTables() {
        let (config, problems) = load("server = [\"nas\"]\n")
        #expect(config == nil)
        #expect(problems == [ConfigProblem(.error, file: fileName, line: 1, .shouldBe("server", SettingKind.tables))])
    }
}
