/// What the keyboard module works through in macOS: the remaps, the tap that catches keys, and what
/// macOS says about the keyboard. The app builds the real ones; tests hand in fakes.
@MainActor
public struct KeyboardSystem {
    /// Sets and undoes the hyper key and the remaps.
    let remapper: KeyRemapper
    /// Catches the keys.
    let keyCatcher: any KeyCatcher
    /// Tells what keeps keys from reaching the tap, such as secure input.
    let state: any KeyboardState

    /// Gathers the parts the keyboard module needs.
    public init(remapper: KeyRemapper, keyCatcher: any KeyCatcher, state: any KeyboardState) {
        self.remapper = remapper
        self.keyCatcher = keyCatcher
        self.state = state
    }
}
