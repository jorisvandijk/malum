/// What a web app's bundle tells the web app executable in its `Info.plist`, and the name of the
/// executable inside Malum.app that every web app is a copy of.
public enum WebAppInfo {
    /// The key whose value is the site the web app opens.
    public static let urlKey = "WebAppURL"
    /// The key whose value is a fingerprint of what the bundle was built from.
    static let sourceKey = "WebAppSource"
    /// The web app executable's name, in Malum.app's `Contents/Helpers`.
    public static let executable = "\(Project.name)WebApp"
}
