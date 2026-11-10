// MARK: - CustomStringConvertible

extension DisplayResolution: CustomStringConvertible {
    /// The size as `macos.toml` writes it, such as `1710x1112`.
    public var description: String {
        "\(width)\(Self.separator)\(height)"
    }
}
