/// Whether Malum has a permission, as far as macOS lets it tell.
public enum PermissionState: Equatable, Sendable {
    /// The permission is granted.
    case granted
    /// The permission isn't granted yet.
    case missing
    /// macOS gives no way to tell, so Malum goes ahead and lets the module find out.
    case unknown
}
