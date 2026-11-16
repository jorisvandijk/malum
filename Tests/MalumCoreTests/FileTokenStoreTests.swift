import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct FileTokenStoreTests {
    let paths = Paths(home: "/Users/test")
    let files = FakeFileSystem()

    private var store: FileTokenStore {
        FileTokenStore(files: files, paths: paths, service: Project.sambaService, account: "joris@nas.local")
    }

    @Test func savedSecretReadsBackFromItsOwnFile() async throws {
        try await store.save("pass word")
        #expect(try await store.token() == "pass word")
        #expect(try await store.isStored())
        let file = "/Users/test/.config/malum/secrets/samba/joris@nas.local"
        #expect(try files.read(file) == "pass word")
        #expect(files.isPrivate(file))
        #expect(files.isPrivate(paths.secretsDirectory))
        #expect(files.isPrivate(Paths.folder(of: file)))
    }

    @Test func missingSecretIsNilAndNotStored() async throws {
        #expect(try await store.token() == nil)
        #expect(try await store.isStored() == false)
        #expect(try await store.remove() == false)
    }

    @Test func removeDeletesTheFile() async throws {
        try await store.save("old")
        #expect(try await store.remove())
        #expect(try await store.token() == nil)
    }

    @Test func tokenHasItsOwnFile() async throws {
        try await FileTokenStore(files: files, paths: paths).save("ghp")
        #expect(try files.read(paths.secret(service: Project.tokenService, account: Project.command)) == "ghp")
    }
}
