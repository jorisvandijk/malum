/// What the window manager's settings ask for, from `window_manager.toml` or the `[window_manager]`
/// table in `malum.toml`.
struct WindowManagerConfig: Equatable, Sendable {
    /// Where an error is reported: the key path inside the settings, and what's wrong, made from the
    /// key's full dotted name.
    typealias Report = ([String], (String) -> MessageText) -> Void

    /// The window manager's id, which names its table and its file in dots.
    static let module = "window_manager"
    /// The action that lets the user click a window and shows what it is.
    static let inspectAction = "inspect_window"
    /// The action that floats the focused window, or puts it back in its place.
    static let toggleFloatAction = "toggle_float"
    /// The action that moves the border between the left window and the rest to the left.
    static let splitLeftAction = "split_left"
    /// The action that moves the border between the left window and the rest to the right.
    static let splitRightAction = "split_right"
    /// The action that makes the focused window in the right column taller.
    static let splitTallerAction = "split_taller"
    /// The action that makes the focused window in the right column shorter.
    static let splitShorterAction = "split_shorter"
    /// The action that stacks the windows of the app in front, or splits them again.
    static let toggleStackAction = "toggle_stack"
    /// The action that shows the next stacked window.
    static let stackNextAction = "stack_next"
    /// The action that shows the previous stacked window.
    static let stackPreviousAction = "stack_previous"
    /// How far the split keys move a border when nothing is set, in percent of the area.
    static let defaultSplitStep = 5
    /// The steps `split_step_percent` can be, in percent of the area.
    static let splitSteps = 1...25
    /// The table of how windows fill the screen and what apps may do with them.
    static let windowsTable = "windows"
    /// The key of the part of the screen windows fill.
    static let frameKey = "frame"
    /// The key that lets cmd+H, cmd+M and cmd+option+M through.
    static let allowKey = "allow_hide_minimize"
    /// The key of how far the split keys move a border.
    static let splitStepKey = "split_step_percent"
    /// The table of windows left alone, by a name the person chooses.
    static let floatTable = "floating_windows"
    /// A floating window's app.
    static let appKey = "app"
    /// A floating window's title pattern.
    static let titleKey = "title"

    /// The window manager's settings in `malum.toml`: only the switch, since the rest goes in
    /// `window_manager.toml`, which `catalog` reads.
    static let schema = ConfigSchema(
        about: "Run or raise apps, windows filling the screen, and floating windows. Its settings go in "
            + "`\(Paths.moduleTOMLName(module))`: see [window manager](window-manager.md).",
        settings: [:], fileCheck: .windowManager)

    /// The catalog of `window_manager.toml`.
    static let catalog = Catalog(
        file: Paths.moduleTOMLName(module),
        tables: [
            CatalogTable(
                name: windowsTable, about: "How windows fill the screen, and what apps may do with them.",
                settings: [
                    CatalogSetting(
                        frameKey,
                        "The part of the screen windows fill: `visible` is below the menu bar and outside the "
                            + "Dock, `full` the whole screen.",
                        .choice(ScreenFrame.allCases.map { .word($0.rawValue, .string($0.rawValue)) }),
                        [.own(windowsTable, frameKey)]),
                    CatalogSetting(
                        allowKey,
                        "Lets cmd+H, cmd+M and cmd+option+M hide an app or minimise a window. Left off, the window "
                            + "manager swallows them, since a hidden app or a minimised window leaves a gap.",
                        .flag, [.own(windowsTable, allowKey)]),
                    CatalogSetting(
                        splitStepKey,
                        "How far `split_left`, `split_right`, `split_taller` and `split_shorter` move a border, "
                            + "in percent of the area. \(defaultSplitStep) when it's left out.",
                        .count(splitSteps), [.own(windowsTable, splitStepKey)]),
                ]),
            CatalogTable(
                name: floatTable, about: "Windows the window manager leaves alone.",
                entries: CatalogEntries(
                    keys: "what floats, such as \"password_prompts\"",
                    settings: [
                        CatalogSetting(
                            appKey, "The app, by bundle ID.", .app(before: "", after: ""),
                            [.own(floatTable, CatalogEntries.entry, appKey)]),
                        CatalogSetting(
                            titleKey,
                            "A pattern for the window's title, such as \"^Picture-in-Picture$\": only windows "
                                + "whose title matches float. Left out, every window of the app floats.",
                            .text(.plain), [.own(floatTable, CatalogEntries.entry, titleKey)]),
                    ], optional: [titleKey])),
        ])

    /// The part of the screen windows fill.
    let frame: ScreenFrame
    /// Whether cmd+H, cmd+M and cmd+option+M are swallowed.
    let blocksHideMinimize: Bool
    /// The windows left alone.
    let floats: [FloatRule]
    /// How far the split keys move a border, in percent of the area.
    let splitStep: Int

    /// Creates a config, by default the one used when nothing is set.
    init(
        frame: ScreenFrame = .visible, blocksHideMinimize: Bool = true,
        floats: [FloatRule] = [], splitStep: Int = defaultSplitStep
    ) {
        self.frame = frame
        self.blocksHideMinimize = blocksHideMinimize
        self.floats = floats
        self.splitStep = splitStep
    }

    /// Reads `text`, the contents of `window_manager.toml`, through `catalog`: the tables it gave,
    /// or nil when an error stops it, and every problem found.
    static func read(file text: String) -> (table: ConfigTable?, problems: [ConfigProblem]) {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.moduleTOMLName(module))
        } catch {
            return (nil, [error])
        }
        // `enabled` is reported by the config, which says it belongs in `malum.toml`.
        reader.unknownKeys(
            reader.document.filter { $0.key != ConfigSchema.switchKey }, at: [], known: catalog.topTables)
        let own = catalog.own(&reader, home: "")
        _ = read(own) { path, text in reader.add(.error, at: path, text(TableReader.dotted(path))) }
        let problems = reader.problemsByLine
        return (reader.hasErrors ? nil : own, problems)
    }

    /// Reads `table`, the tables `catalog` read, whose kinds it has checked, sending each error to
    /// `report`. A float rule with an error is left out.
    static func read(_ table: ConfigTable, report: Report) -> Self {
        var frame = ScreenFrame.visible
        if case .string(let name)? = table.value(at: [windowsTable, frameKey]), let named = ScreenFrame(rawValue: name)
        {
            frame = named
        }
        var splitStep = defaultSplitStep
        if case .integer(let step)? = table.value(at: [windowsTable, splitStepKey]) {
            splitStep = step
        }
        let allows = table.value(at: [windowsTable, allowKey]) == .boolean(true)
        return Self(
            frame: frame, blocksHideMinimize: !allows, floats: floatRules(table[floatTable], report: report),
            splitStep: splitStep)
    }

    /// The float rules in `value`, a table of them by name, leaving out each one with a problem.
    private static func floatRules(_ value: ConfigValue?, report: Report) -> [FloatRule] {
        guard case .table(let rules)? = value else { return [] }
        return rules.sorted { $0.key < $1.key }.compactMap { name, rule in
            guard case .table(let fields) = rule, case .string(let app)? = fields[appKey] else { return nil }
            guard let value = fields[titleKey] else { return FloatRule(app: app, title: nil) }
            guard case .string(let title) = value, compiles(title) else {
                report([floatTable, name, titleKey]) { .shouldBe($0, MessageText.titlePattern) }
                return nil
            }
            return FloatRule(app: app, title: title)
        }
    }

    /// Whether `pattern` is one `Regex` takes.
    private static func compiles(_ pattern: String) -> Bool {
        (try? Regex(pattern)) != nil  // Not compiling is the answer this gives.
    }
}
