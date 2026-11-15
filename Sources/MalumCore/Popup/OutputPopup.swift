/// Shows what a run from the menu writes in the popup, as it comes in. One run at a time: asking
/// for another while one runs only shows the popup again.
@MainActor
public final class OutputPopup {
    /// The id of the list in the popup.
    static let id = "output"

    /// The popup.
    private let center: PopupCenter
    /// The lines.
    private let list = OutputList()
    /// Whether a run is going.
    private(set) var isRunning = false

    /// Adds the output list to `center`.
    public init(center: PopupCenter) {
        self.center = center
        center.register(list, as: Self.id)
    }

    /// Opens the popup on an empty list named `label`, then runs `work`, showing each line it
    /// writes. Returns once `work` is done.
    public func run(_ label: String, work: @MainActor (_ write: @MainActor (String) -> Void) async -> Void) async {
        guard !isRunning else {
            center.show(Self.id)
            return
        }
        isRunning = true
        defer { isRunning = false }
        list.start(label)
        center.show(Self.id)
        await work { [list, center] line in
            list.add(line)
            center.refresh(Self.id)
        }
    }
}
