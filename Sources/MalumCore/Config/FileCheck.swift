/// How a module's own file is checked when its keys aren't a fixed list of settings, such as
/// `keyboard.toml`, whose tables are named after modifiers.
public enum FileCheck: Equatable, Sendable {
    /// `keyboard.toml`, read by `KeyboardConfig`.
    case keyboard

    /// What's wrong with `text`, the file's contents, each at its line.
    func problems(in text: String) -> [ConfigProblem] {
        switch self {
        case .keyboard:
            KeyboardConfig.read(text).problems
        }
    }
}
