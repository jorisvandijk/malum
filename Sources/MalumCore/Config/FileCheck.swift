/// How a module's own file is read when its keys aren't a fixed list of settings under
/// `[settings]`, such as `keyboard.toml` and `window_manager.toml`, whose tables a catalog takes.
public enum FileCheck: Equatable, Sendable {
    /// `keyboard.toml`, read by `KeyboardConfig`, which the module reads again from the file's text.
    case keyboard
    /// `window_manager.toml`, read by `WindowManagerConfig` through its catalog.
    case windowManager

    /// The settings `text`, the file's contents, gives the module, from `document`, the file's
    /// tables, and what's wrong with it, each at its line.
    func read(_ text: String, document: ConfigTable) -> (table: ConfigTable, problems: [ConfigProblem]) {
        switch self {
        case .keyboard:
            return (document, KeyboardConfig.read(text).problems)
        case .windowManager:
            let reading = WindowManagerConfig.read(file: text)
            return (reading.table ?? [:], reading.problems)
        }
    }
}
