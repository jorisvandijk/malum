/// A kind of link or file an app opens, by the name macOS gives it.
public enum OpenTarget: Hashable, Sendable {
    /// Links that start with this scheme, such as `https`.
    case scheme(String)
    /// Files of this type, such as `public.html`.
    case contentType(String)
}
