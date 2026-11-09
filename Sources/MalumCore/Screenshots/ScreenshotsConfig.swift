/// What the screenshots module's settings ask for, from `screenshots.toml` or the `[screenshots]`
/// table in `malum.toml`.
struct ScreenshotsConfig: Equatable, Sendable {
    /// Where an error is reported: the key path inside the settings, and what's wrong, made from the
    /// key's full dotted name.
    typealias Report = ([String], (String) -> MessageText) -> Void

    /// The module's id, which names its table and its file.
    static let module = "screenshots"
    /// The action that takes a screenshot, for `keyboard.toml`.
    static let action = "screenshot"
    /// The key of the folder shots are saved in.
    private static let folderKey = "folder"
    /// The key of the quick colors.
    private static let colorsKey = "colors"
    /// Where shots are saved when nothing is set.
    static let defaultFolder = "~/Documents"
    /// How many quick colors the toolbar has room for.
    static let maxColors = 7

    /// The screenshots module's settings, checked by `read` on top of their kinds.
    static let schema = ConfigSchema(
        about: "Screenshots you crop and draw on before they're saved. See [screenshots](screenshots.md).",
        settings: [
            folderKey: Setting(
                .string, "The folder screenshots are saved in.", default: .string(defaultFolder)),
            colorsKey: Setting(
                .strings,
                "The quick colors in the toolbar, 1 to \(maxColors) as \"#rrggbb\". The first is the color "
                    + "you start with.",
                default: .array(ScreenshotColor.quickDefaults.map { .string($0.hex) })),
        ],
        settingsCheck: .screenshots)

    /// The folder shots are saved in, as written, with `~` not yet expanded.
    let folder: String
    /// The quick colors, the first being the one to start with.
    let colors: [ScreenshotColor]

    /// Creates a config, by default the one used when nothing is set.
    init(folder: String = defaultFolder, colors: [ScreenshotColor] = ScreenshotColor.quickDefaults) {
        self.folder = folder
        self.colors = colors
    }

    /// Reads `table`, whose kinds `schema` has checked, sending each error to `report`. A setting
    /// with an error keeps its default.
    static func read(_ table: ConfigTable, report: Report) -> Self {
        Self(
            folder: folder(table[folderKey], report: report) ?? defaultFolder,
            colors: colors(table[colorsKey], report: report) ?? ScreenshotColor.quickDefaults)
    }

    /// The folder shots are saved in, with `~` expanded by `paths`.
    func folderPath(_ paths: Paths) -> String {
        paths.resolve(folder, relativeTo: paths.home)
    }

    /// The folder at `value`, nil when it's left out, or nil and an error when it's empty.
    private static func folder(_ value: ConfigValue?, report: Report) -> String? {
        guard case .string(let folder)? = value else { return nil }
        guard !folder.isEmpty else {
            report([folderKey]) { .shouldBe($0, MessageText.screenshotFolder) }
            return nil
        }
        return folder
    }

    /// The colors at `value`, nil when they're left out, or nil and an error when one isn't a
    /// color or there are none or too many.
    private static func colors(_ value: ConfigValue?, report: Report) -> [ScreenshotColor]? {
        guard case .array(let items)? = value else { return nil }
        let colors = items.compactMap { item in
            guard case .string(let hex) = item else { return nil as ScreenshotColor? }
            return ScreenshotColor(hex: hex)
        }
        guard colors.count == items.count, (1...maxColors).contains(colors.count) else {
            report([colorsKey]) { .shouldBe($0, MessageText.screenshotColors) }
            return nil
        }
        return colors
    }
}
