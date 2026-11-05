/// Text for the user that knows which of its parts are private, such as paths, so the log can
/// hide them.
///
/// It's written as a string, with private parts marked as `\(private: path)`. The terminal and
/// the menu bar show all of it; the log shows only the public parts.
public struct MessageText: Sendable {
    /// What the log shows in place of a private part.
    public static let placeholder = "<private>"

    /// One piece of the text.
    public enum Part: Equatable, Sendable {
        /// Text anyone may read.
        case shown(String)
        /// Text the log keeps private, such as a path or a host name.
        case hidden(String)
    }

    /// The pieces, in order.
    public let parts: [Part]

    /// Creates text that's all public, such as the reason an error gives.
    public init(_ text: String) {
        parts = [.shown(text)]
    }

    /// Creates text from its pieces.
    private init(parts: [Part]) {
        self.parts = parts
    }

    /// The text with each private part replaced by the placeholder.
    public var redacted: String {
        parts.map { part in
            switch part {
            case .shown(let text):
                text
            case .hidden:
                Self.placeholder
            }
        }.joined()
    }

    /// The private parts, in order.
    public var hidden: [String] {
        parts.compactMap { part in
            guard case .hidden(let text) = part else { return nil }
            return text
        }
    }
}

// MARK: - CustomStringConvertible

extension MessageText: CustomStringConvertible {
    /// All of the text, private parts included.
    public var description: String {
        parts.map { part in
            switch part {
            case .shown(let text), .hidden(let text):
                text
            }
        }.joined()
    }
}

// MARK: - Equatable

extension MessageText: Equatable {
    /// Two texts are equal when they read the same, whichever parts are private.
    public static func == (lhs: MessageText, rhs: MessageText) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: - ExpressibleByStringInterpolation

extension MessageText: ExpressibleByStringInterpolation {
    /// Collects the pieces of a string literal, with `\(private: value)` for private ones.
    public struct StringInterpolation: StringInterpolationProtocol {
        /// The pieces so far.
        fileprivate var parts: [Part] = []

        /// Starts an empty text.
        public init(literalCapacity: Int, interpolationCount: Int) {}

        /// Adds the literal text between the values.
        public mutating func appendLiteral(_ literal: String) {
            guard !literal.isEmpty else { return }
            parts.append(.shown(literal))
        }

        /// Adds a public value.
        public mutating func appendInterpolation<Value>(_ value: Value) {
            parts.append(.shown(String(describing: value)))
        }

        /// Adds a private value, which the log hides.
        public mutating func appendInterpolation<Value>(private value: Value) {
            parts.append(.hidden(String(describing: value)))
        }

        /// Adds another text, keeping its private parts private.
        public mutating func appendInterpolation(_ text: MessageText) {
            parts += text.parts
        }
    }

    /// Creates text from a plain string literal.
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// Creates text from a string literal with values in it.
    public init(stringInterpolation: StringInterpolation) {
        self.init(parts: stringInterpolation.parts)
    }
}
