import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TokenCommandTests {
    private let denied = TokenStoreError.keychain(status: -128, reason: "User canceled the operation.")

    private func command(_ store: FakeTokenStore) -> TokenCommand {
        TokenCommand(store: store, github: FakeGitHub([:], files: FakeFileSystem()))
    }

    @Test func acceptedTokenIsSavedTrimmed() async {
        let store = FakeTokenStore()
        let message = await command(store).save("  good\n")
        #expect(message == Message(.info, "saved the GitHub token in the login keychain"))
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

    @Test func keychainFailureIsReported() async {
        let message = await command(FakeTokenStore(failure: denied)).save("good")
        let reason = "the login keychain answered User canceled the operation."
        #expect(message == Message(.error, "couldn't save the GitHub token: \(reason)"))
    }

    @Test func removeDeletesTheToken() {
        let store = FakeTokenStore("good")
        #expect(command(store).remove() == Message(.info, "removed the GitHub token from the login keychain"))
        #expect(store.current == nil)
    }

    @Test func removeWithoutTokenSaysSo() {
        #expect(command(FakeTokenStore()).remove() == Message(.info, "the login keychain holds no GitHub token"))
    }

    @Test func statusSaysWhetherATokenIsStored() {
        #expect(
            command(FakeTokenStore("good")).status() == Message(.info, "GitHub token: stored in the login keychain"))
        #expect(
            command(FakeTokenStore()).status() == Message(.info, "GitHub token: none, run malum token to add one"))
    }

    @Test func unreadableKeychainIsAWarning() {
        let message = command(FakeTokenStore(failure: .keychain(status: -25293, reason: nil))).status()
        #expect(message == Message(.warn, "couldn't read the GitHub token: the login keychain answered error -25293"))
    }
}
