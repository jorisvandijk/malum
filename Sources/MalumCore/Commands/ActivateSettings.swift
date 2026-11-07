/// Every way Malum runs `activateSettings`, which tells running apps that macOS's settings
/// changed, as System Settings does.
public enum ActivateSettings {
    /// Where macOS keeps `activateSettings`.
    public static let path =
        "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

    /// Tells the apps of the user running it.
    public static let user = Command(path, ["-u"])
}
