/// What the clipboard history works through.
@MainActor
public struct ClipboardSystem {
    /// Reads and writes the history.
    let files: any FileSystem
    /// Where the history folder is.
    let state: StateFolder
    /// The system clipboard.
    let clipboard: any Clipboard
    /// The popup the history shows its list in.
    let popup: PopupCenter

    /// Gathers the parts the clipboard history needs.
    public init(files: any FileSystem, state: StateFolder, clipboard: any Clipboard, popup: PopupCenter) {
        self.files = files
        self.state = state
        self.clipboard = clipboard
        self.popup = popup
    }
}
