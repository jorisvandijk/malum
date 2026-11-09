/// What the Samba module's settings ask for, from `samba.toml` or the `[samba]` table in
/// `malum.toml`.
struct SambaConfig: Equatable, Sendable {
    /// Where an error is reported: the key path inside the settings, and what's wrong, made from the
    /// key's full dotted name.
    typealias Report = ([String], (String) -> MessageText) -> Void

    /// The module's id, which names its table and its file in dots.
    static let module = "samba"
    /// The list of servers.
    private static let serverKey = "server"
    /// A server's name.
    private static let nameKey = "name"
    /// A server's host.
    private static let hostKey = "host"
    /// The user on a server.
    private static let userKey = "user"
    /// A server's shares.
    private static let sharesKey = "shares"

    /// The Samba module's settings, checked by `read` on top of their kinds.
    static let schema = ConfigSchema(
        about: "Samba shares mounted under `/Volumes`. See [Samba](samba.md).",
        settings: [
            serverKey: Setting(
                .tables,
                "The servers, one `[[server]]` each, with `name`, `host`, `user` and `shares`, the list of shares "
                    + "to mount.")
        ],
        settingsCheck: .samba)

    /// The servers.
    let servers: [SambaServer]

    /// Reads `table`, whose kinds `schema` has checked, sending each error to `report`. A server
    /// with an error is left out.
    static func read(_ table: ConfigTable, report: Report) -> Self {
        guard case .array(let items)? = table[serverKey] else { return Self(servers: []) }
        var names = Set<String>()
        let servers: [SambaServer] = items.enumerated().compactMap { index, item in
            guard case .table(let fields) = item else { return nil }
            let path = [serverKey, String(index)]
            guard let server = server(fields, at: path, report: report) else { return nil }
            guard names.insert(server.name).inserted else {
                report(path + [nameKey]) { .takenName($0) }
                return nil
            }
            return server
        }
        return Self(servers: servers)
    }

    /// The server in `fields`, found at `path`, or nil when it has a problem.
    private static func server(_ fields: ConfigTable, at path: [String], report: Report) -> SambaServer? {
        let known = [nameKey, hostKey, userKey, sharesKey]
        for key in fields.keys.sorted() where !known.contains(key) {
            report(path + [key]) { .unknownKey($0, isTable: false) }
        }
        let name = plainName(fields[nameKey], at: path + [nameKey], report: report)
        let host = text(fields[hostKey], at: path + [hostKey], report: report)
        let user = text(fields[userKey], at: path + [userKey], report: report)
        let shares = shareNames(fields[sharesKey], at: path + [sharesKey], report: report)
        guard let name, let host, let user, let shares else { return nil }
        return SambaServer(name: name, host: host, user: user, shares: shares)
    }

    /// The text at `value` with no spaces, or nil and an error when it's missing or isn't that.
    private static func text(_ value: ConfigValue?, at path: [String], report: Report) -> String? {
        guard case .string(let text)? = value, !text.isEmpty, !text.contains(where: \.isWhitespace) else {
            report(path) { .shouldBe($0, MessageText.sambaText) }
            return nil
        }
        return text
    }

    /// The plain name at `value`, or nil and an error.
    private static func plainName(_ value: ConfigValue?, at path: [String], report: Report) -> String? {
        guard case .string(let name)? = value, Paths.isPlainName(name) else {
            report(path) { .notPlainName($0) }
            return nil
        }
        return name
    }

    /// The share names at `value`, at least one, each a plain name, or nil and an error.
    private static func shareNames(_ value: ConfigValue?, at path: [String], report: Report) -> [String]? {
        guard let value, let shares = TableReader.texts(value), !shares.isEmpty, shares.allSatisfy(Paths.isPlainName)
        else {
            report(path) { .shouldBe($0, MessageText.shareList) }
            return nil
        }
        return shares
    }
}
