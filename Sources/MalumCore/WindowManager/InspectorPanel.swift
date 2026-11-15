/// The small window that shows what the window inspector found. `InspectorWindow` in MalumPlatform
/// is the real one.
@MainActor
public protocol InspectorPanel: AnyObject {
    /// Shows `lines`, replacing what it showed before, with a Copy button that calls `onCopy`.
    func show(_ lines: [InspectorLine], onCopy: @escaping @MainActor () -> Void)
}
