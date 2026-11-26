// MARK: - CustomStringConvertible

extension Hotkey: CustomStringConvertible {
    /// The shortcut as messages write it, such as `ctrl+shift+return` or `hyper+space`.
    var description: String {
        (Modifier.names(of: modifiers) + [key.name]).joined(separator: Self.joiner)
    }
}
