/// The two kinds of Homebrew package.
public enum PackageKind: String, CaseIterable, Sendable {
    /// A command-line tool or library.
    case formula
    /// A Mac app or a font.
    case cask

    /// The flag `brew` takes for this kind.
    var flag: String { "--\(rawValue)" }

    /// The setting in system config's table that lists packages of this kind.
    var setting: String {
        switch self {
        case .formula:
            "formulae"
        case .cask:
            "casks"
        }
    }
}
