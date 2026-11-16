/// Every way Malum runs `csreq`, which compiles code signing requirements.
public enum Csreq {
    /// The tool.
    private static let path = "/usr/bin/csreq"

    /// Compiles the requirement that pins the certificate whose SHA-1 is `hash` into the binary
    /// file `output`: a single requirement, which `rcodesign` makes the designated one.
    public static func designated(certificate hash: String, output: String) -> Command {
        Command(path, ["-r=certificate leaf = H\"\(hash)\"", "-b", output])
    }
}
