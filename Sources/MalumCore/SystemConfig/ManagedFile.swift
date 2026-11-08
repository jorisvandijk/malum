/// A config file Malum wrote, as the record of what Malum installed keeps it.
public struct ManagedFile: Codable, Equatable, Sendable {
    /// Where FNV-1a's hash starts.
    private static let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
    /// What FNV-1a's hash is multiplied by for each byte.
    private static let prime: UInt64 = 0x0000_0100_0000_01B3
    /// The base the fingerprint is written in.
    private static let hexRadix = 16
    /// What's added to a file's name for the copy of what was there before Malum overwrote it.
    private static let backupExtension = ".backup"

    /// The app whose file in `apps/` it's written from.
    public let app: String
    /// A fingerprint of what Malum last wrote, to spot changes made to it since.
    public let fingerprint: String

    /// Creates the record of a file written from `app`'s file, holding `text`.
    public init(app: String, text: String) {
        self.app = app
        fingerprint = Self.fingerprint(of: text)
    }

    /// A fingerprint of `text`: its 64-bit FNV-1a hash in hex. Enough to tell whether a file
    /// changed, not meant to resist tampering.
    public static func fingerprint(of text: String) -> String {
        var hash = offsetBasis
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return String(hash, radix: hexRadix)
    }

    /// Where the copy of what was at `path` is kept when Malum overwrites it: next to it, with
    /// `.backup` added to its name.
    static func backupPath(of path: String) -> String {
        path + backupExtension
    }
}
