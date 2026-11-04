/// The two kinds of Homebrew package, as `packages.toml` names them.
public enum PackageKind: String, CaseIterable, Sendable {
    /// A command-line tool or library.
    case formula
    /// A Mac app or a font.
    case cask

    /// The flag `brew` takes for this kind.
    var flag: String { "--\(rawValue)" }

    /// The kind in the plural, for messages.
    var plural: String {
        switch self {
        case .formula:
            "formulae"
        case .cask:
            "casks"
        }
    }
}
