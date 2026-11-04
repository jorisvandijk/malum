/// What the user switched off outside `malum.toml`: safe mode, and the modules they disabled.
/// Overrides win over `malum.toml`, so a module that crashes Malum can be kept off without editing dots.
public struct Overrides: Equatable, Sendable {
    /// Why safe mode is on, or nil when it's off.
    public let safeMode: SafeModeReason?
    /// The modules kept off, by id.
    public let disabled: Set<String>

    /// Creates the overrides. With no arguments, nothing is overridden.
    public init(safeMode: SafeModeReason? = nil, disabled: Set<String> = []) {
        self.safeMode = safeMode
        self.disabled = disabled
    }

    /// The modules that may run, out of those `malum.toml` switches on: none in safe mode, and never
    /// a disabled one.
    public func allowed(_ enabled: Set<String>) -> Set<String> {
        guard safeMode == nil else { return [] }
        return enabled.subtracting(disabled)
    }
}
