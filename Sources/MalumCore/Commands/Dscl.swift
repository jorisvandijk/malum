import Foundation

/// Every way Malum runs `dscl`, which reads and changes the user accounts on this Mac.
public enum Dscl {
    /// Where macOS keeps `dscl`.
    public static let path = "/usr/bin/dscl"
    /// The node that holds this Mac's own accounts.
    private static let localNode = "."
    /// The attribute that holds the path of the user's picture.
    private static let pictureKey = "Picture"
    /// The attribute that holds a copy of the user's picture, which wins over `Picture` when set.
    private static let photoKey = "JPEGPhoto"

    /// Prints the path of `user`'s picture. Fails when there's none.
    public static func readPicture(of user: String) -> Command {
        Command(path, [localNode, "-read", record(of: user), pictureKey])
    }

    /// Makes the picture at `picture` `user`'s picture. Only root can run it.
    public static func setPicture(of user: String, to picture: String) -> Command {
        Command(path, [localNode, "-create", record(of: user), pictureKey, picture])
    }

    /// Removes the copy of `user`'s picture, so the one `setPicture` set shows. Only root can run it.
    public static func removePhoto(of user: String) -> Command {
        Command(path, [localNode, "-delete", record(of: user), photoKey])
    }

    /// The picture's path in the output of `readPicture`, or nil when it names none. A path with a
    /// space in it is on the line after the attribute's name.
    static func picture(in output: String) -> String? {
        let prefix = "\(pictureKey):"
        guard output.hasPrefix(prefix) else { return nil }
        let picture = output.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
        return picture.isEmpty ? nil : picture
    }

    /// The record of `user` in the local node.
    private static func record(of user: String) -> String { "/Users/\(user)" }
}
