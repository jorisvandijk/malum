import Foundation
import MalumCore
import NetFS
import Network
import Synchronization

/// The Mac's Samba mounts, through `getmntinfo`, the Network framework and NetFS, the framework
/// Finder mounts shares with.
public struct SambaVolumes: SambaShares {
    /// The port Samba answers on.
    private static let port: NWEndpoint.Port = 445
    /// How long a server gets to answer, in seconds.
    private static let timeout: TimeInterval = 2
    /// The file system type of a Samba mount.
    private static let fileSystem = "smbfs"
    /// The address scheme of a Samba share.
    private static let scheme = "smb"
    /// NetFS's key for how it may talk to the user, and its value for not at all.
    private static let interface = (key: "UIOption", none: "NoUI")
    /// NetFS's key for a soft mount, which gives errors instead of hanging when the server goes away.
    private static let softMount = "SoftMount"

    /// Creates access to the mounts.
    public init() {}

    /// The mounted file systems of type `smbfs`.
    public func mounts() -> [SambaMount] {
        var list: UnsafeMutablePointer<statfs>?
        let count = getmntinfo(&list, MNT_NOWAIT)
        guard count > 0, let list else { return [] }
        return UnsafeBufferPointer(start: list, count: Int(count)).compactMap { info in
            guard Self.text(info.f_fstypename) == Self.fileSystem else { return nil }
            return SambaMount(source: Self.text(info.f_mntfromname), path: Self.text(info.f_mntonname))
        }
    }

    /// Opens a connection to the Samba port, and says whether it's up before the timeout.
    public func isReachable(_ host: String) async -> Bool {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: Self.port, using: .tcp)
        let reachable = await withCheckedContinuation { continuation in
            let answer = Answer(continuation)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: answer.give(true)
                case .failed, .cancelled, .waiting: answer.give(false)
                case .setup, .preparing: break
                @unknown default: break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + Self.timeout) { answer.give(false) }
        }
        connection.cancel()
        return reachable
    }

    /// Mounts the share through NetFS, off the main thread, since NetFS waits for the server.
    public func mount(_ share: String, from server: SambaServer, password: String) async throws(SambaMountError) {
        var address = URLComponents()
        address.scheme = Self.scheme
        address.host = server.host
        address.path = "/\(share)"
        guard let url = address.url else { throw .noShare }
        let user = server.user
        let mounting = Task.detached { Self.mount(url, user: user, password: password) }  // SAFETY: own copies only.
        let status = await mounting.value
        guard status == 0 else { throw SambaMountError(status: status) }
    }

    /// Mounts `url` as `user` with `password`, with no dialog, and gives back NetFS's status.
    private static func mount(_ url: URL, user: String, password: String) -> Int32 {
        let open = NSMutableDictionary(dictionary: [interface.key: interface.none])
        let options = NSMutableDictionary(dictionary: [softMount: true])
        return NetFSMountURLSync(
            url as CFURL, nil, user as CFString, password as CFString, open as CFMutableDictionary,
            options as CFMutableDictionary, nil)
    }

    /// The C string in the fixed-size `field` of a `statfs`.
    private static func text<Field>(_ field: Field) -> String {
        withUnsafeBytes(of: field) { String(bytes: $0.prefix { $0 != 0 }, encoding: .utf8) ?? "" }
    }
}

/// Gives a reachability check its answer once, from whichever comes first.
private final class Answer: Sendable {
    /// Waits for the answer until it's given.
    private let waiting: Mutex<CheckedContinuation<Bool, Never>?>

    /// Creates the answer for `continuation`.
    init(_ continuation: CheckedContinuation<Bool, Never>) {
        waiting = Mutex(continuation)
    }

    /// Gives `answer` when none was given yet.
    func give(_ answer: Bool) {
        let continuation = waiting.withLock { waiting in
            defer { waiting = nil }
            return waiting
        }
        continuation?.resume(returning: answer)
    }
}
