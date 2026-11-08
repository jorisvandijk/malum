/// Every way Malum runs `shasum`, which checks a download against the checksum next to it.
public enum Shasum {
    /// Where macOS keeps `shasum`.
    public static let path = "/usr/bin/shasum"
    /// The SHA-2 variant the releases use.
    private static let algorithm = "256"

    /// Prints the SHA-256 checksum of `file`.
    public static func sha256(_ file: String) -> Command {
        Command(path, ["-a", algorithm, file])
    }

    /// The checksum at the start of `text`, `shasum`'s output or a `.sha256` file, in lowercase,
    /// or nil when there's none.
    static func checksum(in text: String) -> String? {
        text.split(whereSeparator: \.isWhitespace).first.map { $0.lowercased() }
    }
}
