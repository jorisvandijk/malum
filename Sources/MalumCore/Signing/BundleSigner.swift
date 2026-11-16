/// Signs an app bundle with Malum's key file, through `rcodesign`, without ever touching the one
/// that runs.
///
/// The bundle is copied to a staging path next to its destination, the copy is signed and checked,
/// and only then swapped into place in one step. When any step fails, the app that was there stays.
public struct BundleSigner: Sendable {
    /// What's added to the destination's path to stage the copy.
    private static let stagingSuffix = ".staged"

    /// Runs `rcodesign` and `codesign`.
    private let runner: any CommandRunner
    /// Copies, swaps and removes the bundles.
    private let files: any FileSystem
    /// The `rcodesign` to sign with.
    private let tool: String

    /// Creates the signer, which signs with the `rcodesign` at `tool`.
    public init(runner: any CommandRunner, files: any FileSystem, tool: String) {
        self.runner = runner
        self.files = files
        self.tool = tool
    }

    /// Whether the bundle at `bundle` is intact and signed with `identity`'s certificate.
    public func isSigned(_ bundle: String, by identity: SigningIdentity) async -> Bool {
        await runner.run(Codesign.verify(bundle, identity: identity.hash)).succeeded
    }

    /// Puts a copy of the bundle `source`, signed with `identity`, at `destination`. `source` may
    /// be `destination` itself.
    public func install(
        _ source: String, at destination: String, identity: SigningIdentity
    ) async throws(SigningError) {
        let staged = destination + Self.stagingSuffix
        do {
            try removeLeftover(staged)
            try files.copy(source, to: staged)
        } catch {
            throw .files(error)
        }
        do {
            try await sign(staged, identity: identity)
            try swapIn(staged, at: destination)
        } catch {
            try? removeLeftover(staged)  // Best effort: the next install removes it too.
            throw error
        }
    }

    /// Signs the copy at `staged` and checks the result.
    private func sign(_ staged: String, identity: SigningIdentity) async throws(SigningError) {
        let signed = await runner.run(Rcodesign.sign(staged, identity: identity, tool: tool))
        guard signed.succeeded else { throw .unsigned(reason: signed.reason) }
        let verified = await runner.run(Codesign.verify(staged, identity: identity.hash))
        guard verified.succeeded else { throw .unverified(reason: verified.reason) }
    }

    /// Puts `staged` at `destination` in one step, then removes the old bundle, which the swap
    /// left at `staged`. A running app keeps running from the files it already opened.
    private func swapIn(_ staged: String, at destination: String) throws(SigningError) {
        do {
            try files.replace(destination, with: staged)
        } catch {
            throw .files(error)
        }
    }

    /// Removes what an earlier install left at `staged`.
    private func removeLeftover(_ staged: String) throws(FileSystemError) {
        guard files.item(at: staged) != nil else { return }
        try files.remove(staged)
    }
}
