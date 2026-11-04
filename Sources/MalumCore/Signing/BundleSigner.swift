/// Signs an app bundle with Malum's certificate without ever touching the one that runs.
///
/// The bundle is copied to a staging path next to its destination, the copy is signed and checked,
/// and only then swapped into place in one step. When any step fails, the app that was there stays.
public struct BundleSigner: Sendable {
    /// What's added to the destination's path to stage the copy.
    private static let stagingSuffix = ".staged"

    /// Runs `codesign`.
    private let runner: any CommandRunner
    /// Copies, swaps and removes the bundles.
    private let files: any FileSystem

    /// Creates the signer.
    public init(runner: any CommandRunner, files: any FileSystem) {
        self.runner = runner
        self.files = files
    }

    /// Whether the bundle at `bundle` is intact and signed with the certificate `identity`.
    public func isSigned(_ bundle: String, by identity: String) async -> Bool {
        await runner.run(Codesign.verify(bundle, identity: identity)).succeeded
    }

    /// Puts a copy of the bundle `source`, signed with the certificate `identity`, at
    /// `destination`. `source` may be `destination` itself.
    public func install(_ source: String, at destination: String, identity: String) async throws(SigningError) {
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
    private func sign(_ staged: String, identity: String) async throws(SigningError) {
        let signed = await runner.run(Codesign.sign(staged, identity: identity))
        guard signed.succeeded else { throw .unsigned(reason: signed.reason) }
        let verified = await runner.run(Codesign.verify(staged, identity: identity))
        guard verified.succeeded else { throw .unverified(reason: verified.reason) }
    }

    /// Puts `staged` at `destination` in one step, then removes the old bundle, which the swap
    /// left at `staged`. A running app keeps running from the files it already opened.
    private func swapIn(_ staged: String, at destination: String) throws(SigningError) {
        do {
            try files.exchange(staged, destination)
        } catch {
            throw .files(error)
        }
        try? files.remove(staged)  // The new bundle is in place; the next install removes a leftover.
    }

    /// Removes what an earlier install left at `staged`.
    private func removeLeftover(_ staged: String) throws(FileSystemError) {
        guard files.item(at: staged) != nil else { return }
        try files.remove(staged)
    }
}
