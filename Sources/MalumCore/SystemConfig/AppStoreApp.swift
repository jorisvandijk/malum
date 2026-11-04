/// An app from the Mac App Store, as `packages.toml` lists it.
public struct AppStoreApp: Equatable, Sendable {
    /// The name it has in `packages.toml`, for messages.
    public let name: String
    /// Its App Store ID, the number in its App Store link.
    public let id: Int

    /// Creates the app called `name` with the App Store ID `id`.
    public init(_ name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
