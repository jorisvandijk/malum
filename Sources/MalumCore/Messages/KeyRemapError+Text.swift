/// The words for why the key remaps couldn't be set or undone.
extension KeyRemapError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unset(let reason):
            .couldnt("remap the keys", "\(reason)")
        case .uncleared(let reason):
            .couldnt("undo the key remaps", "\(reason)")
        case .marker(let error):
            error.text
        }
    }
}
