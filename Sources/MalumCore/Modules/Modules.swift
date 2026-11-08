/// Every module Malum has. The app runs them, and `malum run` and the docs tool read their schemas,
/// so they all take them from here.
@MainActor
public enum Modules {
    /// Builds every module, in the order they're started. Building one starts nothing, so the docs
    /// tool builds them only to read their schemas.
    public static func all() -> [any Module] {
        []
    }
}
