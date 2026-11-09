/// What the window manager's settings ask for, from `window_manager.toml` or the `[window_manager]`
/// table in `malum.toml`.
struct WindowManagerConfig: Equatable, Sendable {
    /// Where an error is reported: the key path inside the settings, and what's wrong, made from the
    /// key's full dotted name.
    typealias Report = ([String], (String) -> MessageText) -> Void

    /// The window manager's id, which names its table and its file in dots.
    static let module = "window_manager"
    /// The key of the part of the screen windows fill.
    private static let frameKey = "frame"
    /// The key that hides the other apps on run or raise.
    private static let hideOthersKey = "hide_others"
    /// The key that blocks cmd+H, cmd+M and cmd+option+M.
    private static let blockKey = "block_hide_minimize"
    /// The list of float rules.
    private static let floatKey = "float"
    /// A float rule's app.
    private static let appKey = "app"
    /// A float rule's title pattern.
    private static let titleKey = "title"

    /// The window manager's settings, checked by `read` on top of their kinds.
    static let schema = ConfigSchema(
        about: "Run or raise apps, windows filling the screen, and floating windows. "
            + "See [window manager](window-manager.md).",
        settings: [
            frameKey: Setting(
                .string,
                "The part of the screen windows fill: \"\(ScreenFrame.visible.rawValue)\" (below the menu bar and "
                    + "outside the Dock) or \"\(ScreenFrame.full.rawValue)\" (the whole screen).",
                default: .string(ScreenFrame.visible.rawValue)),
            hideOthersKey: Setting(
                .boolean, "Hides every other app when an app is run or raised.", default: .boolean(true)),
            blockKey: Setting(
                .boolean, "Swallows cmd+H, cmd+M and cmd+option+M, which would hide an app or minimise a window.",
                default: .boolean(true)),
            floatKey: Setting(
                .tables,
                "Apps whose windows are left alone, each with `app` (a bundle ID) and an optional `title`, "
                    + "a pattern that only matching windows float by."),
        ],
        settingsCheck: .windowManager)

    /// The part of the screen windows fill.
    let frame: ScreenFrame
    /// Whether run or raise hides every other app.
    let hidesOthers: Bool
    /// Whether cmd+H, cmd+M and cmd+option+M are swallowed.
    let blocksHideMinimize: Bool
    /// The windows left alone.
    let floats: [FloatRule]

    /// Creates a config, by default the one used when nothing is set.
    init(
        frame: ScreenFrame = .visible, hidesOthers: Bool = true, blocksHideMinimize: Bool = true,
        floats: [FloatRule] = []
    ) {
        self.frame = frame
        self.hidesOthers = hidesOthers
        self.blocksHideMinimize = blocksHideMinimize
        self.floats = floats
    }

    /// Reads `table`, whose kinds `schema` has checked, sending each error to `report`. A value with
    /// an error takes its default, and a float rule with one is left out.
    static func read(_ table: ConfigTable, report: Report) -> Self {
        var frame = ScreenFrame.visible
        if case .string(let name)? = table[frameKey] {
            if let named = ScreenFrame(rawValue: name) {
                frame = named
            } else {
                report([frameKey]) { .shouldBe($0, MessageText.screenFrame) }
            }
        }
        let floats = floatRules(table[floatKey], report: report)
        return Self(
            frame: frame, hidesOthers: boolean(table[hideOthersKey]), blocksHideMinimize: boolean(table[blockKey]),
            floats: floats)
    }

    /// The value of a switch that's on unless it says false.
    private static func boolean(_ value: ConfigValue?) -> Bool {
        value != .boolean(false)
    }

    /// The float rules in `value`, a list of tables, leaving out each one with a problem.
    private static func floatRules(_ value: ConfigValue?, report: Report) -> [FloatRule] {
        guard case .array(let items)? = value else { return [] }
        return items.enumerated().compactMap { index, item in
            guard case .table(let rule) = item else { return nil }
            return floatRule(rule, at: [floatKey, String(index)], report: report)
        }
    }

    /// The float rule `rule`, found at `path`, or nil when its app or its title has a problem.
    private static func floatRule(_ rule: ConfigTable, at path: [String], report: Report) -> FloatRule? {
        for key in rule.keys.sorted() where ![appKey, titleKey].contains(key) {
            report(path + [key]) { .unknownKey($0, isTable: false) }
        }
        guard case .string(let app)? = rule[appKey], AppBundle.isBundleID(app) else {
            report(path + [appKey]) { .notBundleID($0) }
            return nil
        }
        guard let value = rule[titleKey] else { return FloatRule(app: app, title: nil) }
        guard case .string(let title) = value, (try? Regex(title)) != nil else {
            // A pattern that doesn't compile is the expected answer here, reported as a problem.
            report(path + [titleKey]) { .shouldBe($0, MessageText.titlePattern) }
            return nil
        }
        return FloatRule(app: app, title: title)
    }
}
