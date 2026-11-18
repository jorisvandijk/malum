/// Every way Malum runs `dsimport`, which writes a picture into a user account. `dscl` can't write
/// the picture's bytes itself.
public enum Dsimport {
    /// Where macOS keeps `dsimport`.
    public static let path = "/usr/bin/dsimport"
    /// The node that holds this Mac's own accounts.
    private static let localNode = "/Local/Default"
    /// Adds to the account instead of replacing it.
    private static let merge = "M"
    /// The first line of an import file: the end of line, escape, field and value characters, then
    /// that each line names a user and the file that holds their picture.
    private static let header = """
        0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName \
        externalbinary:dsAttrTypeStandard:JPEGPhoto
        """

    /// Writes the account pictures that the import file `file` lists. Only root can run it.
    public static func importPhoto(from file: String) -> Command {
        Command(path, [file, localNode, merge])
    }

    /// The import file that makes the JPEG at `photo` the picture `user`'s account keeps.
    static func photoFile(of user: String, photo: String) -> String {
        "\(header)\n\(user):\(photo)\n"
    }
}
