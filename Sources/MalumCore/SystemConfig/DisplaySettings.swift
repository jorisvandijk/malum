/// Sets `[display]` in `macos.toml`: the size the Mac's own screen shows things at, the choice
/// System Settings offers between "Larger Text" and "More Space". A key taken out of the file
/// leaves the screen as it is.
@MainActor
struct DisplaySettings {
    /// The table of the screen's settings.
    nonisolated static let table = "display"
    /// The key that holds the size, such as `"1710x1112"`.
    nonisolated static let resolutionKey = "resolution"

    /// The Mac's own screen.
    private let display: any Display

    /// Creates the part, which sets the screen through `display`.
    init(display: any Display) {
        self.display = display
    }

    /// The size in `[display]`, or nil when it sets none, adding a problem to `reader` when it's wrong.
    static func read(_ reader: inout TableReader) -> DisplayResolution? {
        guard reader.document[table] != nil else { return nil }
        let display = reader.table(reader.document, table, at: [])
        reader.unknownKeys(display, at: [table], known: [resolutionKey])
        guard let value = display[resolutionKey] else { return nil }
        let path = [table, resolutionKey]
        guard case .string(let text) = value else {
            reader.expect(path, SettingKind.string)
            return nil
        }
        guard let resolution = DisplayResolution(text) else {
            reader.add(.error, at: path, .notResolution(TableReader.dotted(path)))
            return nil
        }
        return resolution
    }

    /// Shows the screen at `wanted` when it shows another size. Says whether it worked.
    func set(_ wanted: DisplayResolution?, report: (Message) -> Void) -> Bool {
        guard let wanted else { return true }
        guard let now = display.resolution() else {
            report(.screenOff)
            return true
        }
        guard now != wanted else { return true }
        do {
            try display.show(wanted)
        } catch {
            report(.failed(.setResolution, error))
            return false
        }
        report(.resolutionSet(wanted, was: now))
        return true
    }
}
