/// Malum's signing key and certificate, as the files `rcodesign` signs with.
public struct SigningIdentity: Equatable, Sendable {
    /// The certificate's SHA-1, which every signature's designated requirement pins.
    public let hash: String
    /// The file that holds the certificate and its key.
    public let keyFile: String
    /// The compiled designated requirement.
    public let requirement: String

    /// Creates the identity whose certificate has the SHA-1 `hash`, in `keyFile`, with its
    /// compiled designated requirement in `requirement`.
    public init(hash: String, keyFile: String, requirement: String) {
        self.hash = hash
        self.keyFile = keyFile
        self.requirement = requirement
    }
}
