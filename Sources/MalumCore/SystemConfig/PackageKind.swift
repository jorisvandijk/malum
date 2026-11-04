/// The two kinds of Homebrew package, as `packages.toml` names them.
public enum PackageKind: String, CaseIterable, Sendable {
    /// A command-line tool or library.
    case formula
    /// A Mac app or a font.
    case cask

    /// The flag `brew` takes for this kind.
    var flag: String { "--\(rawValue)" }

    /// The kind as messages name it, with Homebrew in front, so it's clear what a cask is.
    var label: String { "Homebrew \(rawValue)" }

    /// The kind in the plural, as messages name it.
    var plural: String {
        switch self {
        case .formula:
            "Homebrew formulae"
        case .cask:
            "Homebrew casks"
        }
    }
}
