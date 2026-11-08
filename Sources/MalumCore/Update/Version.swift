/// A release version, `x.y.z`, compared part by part.
public struct Version: Comparable, Sendable, CustomStringConvertible {
    /// How many numbers a version has.
    private static let partCount = 3
    /// What a tag has in front of its version.
    private static let tagPrefix = "v"

    /// The numbers, major first.
    private let parts: [Int]

    /// Reads `0.2.0`, or a tag such as `v0.2.0`, or gives nil when it isn't three numbers, as for a
    /// build that says `dev`.
    public init?(_ text: String) {
        let plain = text.hasPrefix(Self.tagPrefix) ? text.dropFirst(Self.tagPrefix.count) : Substring(text)
        let pieces = plain.split(separator: ".", omittingEmptySubsequences: false)
        let parts = pieces.compactMap { Int($0) }
        guard pieces.count == Self.partCount, parts.count == Self.partCount, parts.allSatisfy({ $0 >= 0 }) else {
            return nil
        }
        self.parts = parts
    }

    /// The version as `x.y.z`.
    public var description: String { parts.map(String.init).joined(separator: ".") }

    /// Whether `lhs` comes before `rhs`.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.parts.lexicographicallyPrecedes(rhs.parts)
    }
}
