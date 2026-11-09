/// Says when the Mac's network changes, such as joining another Wi-Fi network or a VPN coming up.
@MainActor
public protocol NetworkWatch: AnyObject {
    /// Calls `onChange` after each change, until `stopWatching`.
    func watch(_ onChange: @escaping @MainActor () -> Void)
    /// Stops calling back.
    func stopWatching()
}
