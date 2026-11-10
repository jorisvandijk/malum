/// Every way Malum runs `nvram`, which reads and changes the settings the Mac keeps for its startup.
public enum Nvram {
    /// Where macOS keeps `nvram`.
    public static let path = "/usr/sbin/nvram"
    /// The variable that mutes the sound the Mac makes when it starts up.
    static let startupMute = "StartupMute"
    /// The value of `startupMute` that mutes the sound.
    static let muted = "%01"
    /// The value of `startupMute` that lets the sound play.
    static let unmuted = "%00"

    /// Prints whether the startup sound is muted. Fails when the variable was never set.
    public static let readStartupMute = Command(path, [startupMute])

    /// Mutes the startup sound when `mute` is set, and lets it play when not. Only root can run it.
    public static func setStartupMute(_ mute: Bool) -> Command {
        Command(path, ["\(startupMute)=\(mute ? muted : unmuted)"])
    }

    /// Whether the output of `readStartupMute` says the startup sound is muted.
    static func isMuted(_ output: String) -> Bool {
        output.split(whereSeparator: \.isWhitespace).last.map(String.init) == muted
    }
}
