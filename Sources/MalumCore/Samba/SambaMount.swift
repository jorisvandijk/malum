/// A Samba share macOS has mounted.
public struct SambaMount: Equatable, Sendable {
    /// The server's host, in lower case.
    public let host: String
    /// The share's name.
    public let share: String
    /// Where it's mounted, such as `/Volumes/media`.
    public let path: String

    /// The mount of `source`, as macOS names it, such as `//joris@nas.local/media`, at `path`, or nil
    /// when `source` isn't a Samba share.
    public init?(source: String, path: String) {
        let marker = "//"
        guard source.hasPrefix(marker) else { return nil }
        let place = source.dropFirst(marker.count).split(separator: "@").last ?? ""
        guard let slash = place.firstIndex(of: "/") else { return nil }
        let host = place[..<slash]
        let share = place[place.index(after: slash)...]
        guard !host.isEmpty, !share.isEmpty else { return nil }
        self.host = host.lowercased()
        self.share = String(share).removingPercentEncoding ?? String(share)
        self.path = path
    }

    /// Whether this is `share` on `server`.
    func isShare(_ share: String, on server: SambaServer) -> Bool {
        host == server.host.lowercased() && self.share.lowercased() == share.lowercased()
    }
}
