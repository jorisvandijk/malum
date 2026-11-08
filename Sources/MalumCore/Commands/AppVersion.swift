/// Runs a downloaded copy of Malum itself, to ask which version it is before it's swapped in.
public enum AppVersion {
    /// Asks the Malum executable at `executable` for its version.
    public static func ask(_ executable: String) -> Command {
        Command(executable, ["--version"])
    }
}
