/// Why the token couldn't be read, stored or removed.
public enum TokenStoreError: Error, Equatable, Sendable {
    /// Its file couldn't be read, written or removed.
    case file(FileSystemError)
}
