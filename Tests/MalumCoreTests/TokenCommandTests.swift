import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TokenCommandTests {
    private let denied = TokenStoreError.file(.unwritable(path: "/s", reason: "denied"))

    private func command(_ store: FakeTokenStore) -> TokenCommand {
        TokenCommand(store: store, github: FakeGitHub([:], files: FakeFileSystem()))
    }

    @Test func acceptedTokenIsSavedTrimmed() async {
        let store = FakeTokenStore()
        let message = await command(store).save("  good\n")
        #expect(message == Message(.info, "saved the GitHub token in Malum's secrets"))
        #expect(store.current == "good")
    }

    @Test func newTokenReplacesTheOldOne() async {
        let store = FakeTokenStore("old")
        _ = await command(store).save("good")
        #expect(store.current == "good")
    }

    @Test(arguments: [nil, "", "  \n"])
    func emptyTokenIsRefused(entered: String?) async {
        let store = FakeTokenStore("old")
        let message = await command(store).save(entered)
        #expect(message == Message(.error, "couldn't save the GitHub token: no token was entered"))
        #expect(store.current == "old")
    }

    @Test func refusedTokenIsNotSaved() async {
        let store = FakeTokenStore()
        let message = await command(store).save("wrong")
        let reason = "GitHub refused the token, run malum token with a new one"
        #expect(message == Message(.error, "couldn't save the GitHub token: \(reason)"))
        #expect(store.current == nil)
    }

    @Test func storeFailureIsReported() async {
        let message = await command(FakeTokenStore(failure: denied)).save("good")
        let reason = "couldn't write /s: denied"
        #expect(message == Message(.error, "couldn't save the GitHub token: \(reason)"))
    }

    @Test func removeDeletesTheToken() async {
        let store = FakeTokenStore("good")
        #expect(await command(store).remove() == Message(.info, "removed the GitHub token from Malum's secrets"))
        #expect(store.current == nil)
    }

    @Test func removeWithoutTokenSaysSo() async {
        #expect(await command(FakeTokenStore()).remove() == Message(.info, "Malum's secrets hold no GitHub token"))
    }

    @Test func statusSaysWhetherATokenIsStored() async {
        #expect(
            await command(FakeTokenStore("good")).status()
                == Message(.info, "GitHub token: stored in Malum's secrets"))
        #expect(
            await command(FakeTokenStore()).status() == Message(.info, "GitHub token: none, run malum token to add one")
        )
    }

    @Test func unreadableKeychainIsAWarning() async {
        let message = await command(FakeTokenStore(failure: .file(.unreadable(path: "/s", reason: "denied")))).status()
        #expect(message == Message(.warn, "couldn't read the GitHub token: couldn't read /s: denied"))
    }
}
