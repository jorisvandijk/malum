import Foundation

/// A short fingerprint of some bytes that stays the same from run to run, to notice the same image
/// copied again. It's FNV-1a: fast, and good enough to tell images apart.
enum Fingerprint {
    /// FNV-1a's 64-bit starting value.
    private static let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
    /// FNV-1a's 64-bit prime.
    private static let prime: UInt64 = 0x0000_0100_0000_01b3
    /// Hexadecimal, for the text form.
    private static let hexadecimal = 16

    /// The fingerprint of `data`, as hexadecimal text.
    static func of(_ data: Data) -> String {
        let hash = data.reduce(offsetBasis) { ($0 ^ UInt64($1)) &* prime }
        return "\(data.count)-\(String(hash, radix: hexadecimal))"
    }
}
