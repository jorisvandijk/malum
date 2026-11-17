/// The words for the MarkEdit extensions system config installs from `apps/markedit.toml`.
extension MessageText {
    /// Installing the extensions MarkEdit lists.
    static let installMarkEditExtensions: MessageText = "install \(markEditExtensions)"

    /// Reading MarkEdit's registry of extensions.
    static let readMarkEditRegistry: MessageText = "read MarkEdit's list of extensions"

    /// A MarkEdit extension, as the install and remove messages name it.
    static let markEditExtension: MessageText = "MarkEdit extension"

    /// MarkEdit extensions, in the plural.
    static let markEditExtensions: MessageText = "MarkEdit extensions"

    /// What MarkEdit's list of extensions should hold.
    static var markEditExtensionList: MessageText { "a list of MarkEdit extension ids, such as \"markedit-preview\"" }
}

extension Message {
    /// The MarkEdit extension `id` was installed at `version`.
    static func installed(markEditExtension id: String, version: String) -> Message {
        Message(.info, "installed \(MessageText.markEditExtension) \(id) \(version)")
    }

    /// The MarkEdit extension `id` couldn't be installed.
    static func installFailed(markEditExtension id: String, _ error: any Error) -> Message {
        failed("install \(MessageText.markEditExtension) \(id)", error)
    }

    /// The MarkEdit extension `id` was removed.
    static func removed(markEditExtension id: String) -> Message {
        Message(.info, "removed \(MessageText.markEditExtension) \(id)")
    }

    /// The MarkEdit extension `id` couldn't be removed.
    static func removeFailed(markEditExtension id: String, _ error: any Error) -> Message {
        failed("remove \(MessageText.markEditExtension) \(id)", error)
    }

    /// Every listed MarkEdit extension is at its latest version.
    static var markEditExtensionsUpToDate: Message {
        Message(.info, "every listed \(MessageText.markEditExtension) is up to date")
    }
}

extension MarkEditError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .unreadableRegistry:
            "MarkEdit's registry sent a list \(Project.name) can't read"
        case .unknown(let id):
            "MarkEdit's registry has no extension called \(id)"
        case .checksum(let id):
            "the download of \(id) doesn't match the checksum MarkEdit's registry gives"
        }
    }
}
