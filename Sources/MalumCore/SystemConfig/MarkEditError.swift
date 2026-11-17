/// Why a MarkEdit extension couldn't be installed.
enum MarkEditError: Error, Equatable {
    /// MarkEdit's registry sent something that isn't its list of extensions.
    case unreadableRegistry
    /// The registry has no extension with the id.
    case unknown(id: String)
    /// The download doesn't match the checksum the registry gives.
    case checksum(id: String)
}
