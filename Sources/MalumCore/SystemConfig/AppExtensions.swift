/// Where an app's extensions come from, which decides what their ids look like and what installs
/// them.
enum AppExtensions: Sendable {
    /// VSCodium's, from Open VSX through `codium`, as `publisher.name`.
    case vscodium
    /// MarkEdit's, from its registry, by the registry's id, as scripts in the folder `scripts`,
    /// relative to home.
    case markEdit(scripts: String)

    /// Whether `id` is an id of this kind.
    func isID(_ id: String) -> Bool {
        switch self {
        case .vscodium:
            Codium.isExtensionID(id)
        case .markEdit:
            MarkEditExtensions.isID(id)
        }
    }

    /// What the list of ids should hold, for the error when it doesn't.
    var expected: MessageText {
        switch self {
        case .vscodium:
            .extensionList
        case .markEdit:
            .markEditExtensionList
        }
    }
}
