import Foundation

/// Web addresses in dots, such as a web app's site or a bookmark.
enum WebAddress {
    /// The schemes a web address takes.
    private static let schemes = ["http", "https"]

    /// `text` as a URL when it's a web address, `http` or `https` with a host, or nil otherwise.
    static func url(_ text: String) -> URL? {
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(), schemes.contains(scheme),
            url.host?.isEmpty == false
        else { return nil }
        return url
    }
}
