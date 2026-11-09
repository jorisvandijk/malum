/// A color to draw with on a screenshot, written in the config as `"#rrggbb"`.
public struct ScreenshotColor: Equatable, Hashable, Sendable {
    /// What starts a color's text.
    private static let mark = "#"
    /// How many hex digits make one channel.
    private static let channelDigits = 2
    /// How many channels a color has: red, green and blue.
    private static let channelCount = 3
    /// The base the digits are written in.
    private static let radix = 16
    /// The quick colors when none are set: red, orange, yellow, green, blue, white and black.
    static let quickDefaults = ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#007aff", "#ffffff", "#000000"]
        .compactMap(Self.init(hex:))

    /// The red channel, 0 to 255.
    public let red: UInt8
    /// The green channel, 0 to 255.
    public let green: UInt8
    /// The blue channel, 0 to 255.
    public let blue: UInt8

    /// Creates a color from its channels.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// The color as `"#rrggbb"`, the way the config writes it.
    public var hex: String {
        Self.mark
            + [red, green, blue].map { channel in
                let digits = String(channel, radix: Self.radix)
                return String(repeating: "0", count: Self.channelDigits - digits.count) + digits
            }.joined()
    }

    /// Reads `hex`, such as `"#ff3b30"` in either case, or nil when it isn't one.
    public init?(hex: String) {
        guard hex.hasPrefix(Self.mark) else { return nil }
        let digits = Array(hex.dropFirst(Self.mark.count))
        guard digits.count == Self.channelDigits * Self.channelCount, digits.allSatisfy(\.isHexDigit) else {
            return nil
        }
        let channels = stride(from: 0, to: digits.count, by: Self.channelDigits).compactMap { start in
            UInt8(String(digits[start..<start + Self.channelDigits]), radix: Self.radix)
        }
        guard channels.count == Self.channelCount, let red = channels.first, let blue = channels.last else {
            return nil
        }
        self.init(red: red, green: channels[1], blue: blue)
    }
}
