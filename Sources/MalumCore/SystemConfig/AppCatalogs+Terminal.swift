/// The catalogs of kitty and newsboat, whose settings go into lines of their own config files.
extension AppCatalogs {
    // MARK: - kitty

    /// A setting in kitty's `kitty.conf`, from the block of settings.
    private static func kitty(_ key: String) -> CatalogSetting.Target {
        .file([kittySettings, key])
    }

    /// A colour in kitty's `kitty.conf`, from the block of colours, which comes first.
    private static func kittyColor(_ key: String) -> CatalogSetting.Target {
        .file([kittyTheme, key])
    }

    /// The tables kitty's `kitty.conf` is written from: the colours first, then the settings, then
    /// the shortcuts.
    static let kittyTheme = "theme"
    /// The block of settings.
    static let kittySettings = "settings"
    /// The block of shortcuts, each written with `map`.
    static let kittyShortcuts = "keybindings"

    /// The font sizes kitty takes, in points.
    private static let kittyFontSizes = 4.0...200.0
    /// The margins kitty takes around a window, in points.
    private static let kittyMargins = 0.0...100.0
    /// The scrollback kitty takes, in lines.
    private static let kittyScrollback = 0...Int.max

    /// How kitty names a shortcut: its own words for the modifiers, joined by `+`, and its own names
    /// for keys that aren't a letter or a digit. kitty has no fn.
    private static let kittyShortcut = ShortcutStyle.text(
        names: [.ctrl: "ctrl", .option: "alt", .cmd: "cmd", .shift: "shift"], fn: nil, joiner: "+",
        keys: [
            "return": "enter", "delete": "backspace", "delete_forward": "delete", "minus": "-", "equal": "=",
            "open_bracket": "[", "close_bracket": "]", "backslash": "\\", "semicolon": ";", "quote": "'",
            "grave": "`", "comma": ",", "period": ".", "slash": "/",
        ])

    /// The eight terminal colours by name, in the order kitty numbers them.
    private static let terminalColors = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]

    /// The settings of `[colors.normal]` or `[colors.bright]`: each terminal colour, written to
    /// kitty's numbered colour from `first`.
    private static func kittyPalette(from first: Int, _ about: String) -> [CatalogSetting] {
        terminalColors.enumerated().map { index, name in
            CatalogSetting(name, "\(about) \(name).", .color, [kittyColor("color\(first + index)")])
        }
    }

    /// The setting `name` in `[shortcuts]`, which does `about` by running kitty's `action`.
    private static func kittyAction(_ name: String, _ about: String, _ action: String) -> CatalogSetting {
        CatalogSetting(
            name, about, .shortcutKeys(kittyShortcut), [.fileKeys(table: [kittyShortcuts], value: .string(action))])
    }

    /// `apps/kitty.toml`. Malum always has kitty listen for commands on its socket, which opening a
    /// new tab from the menu bar needs, and draws the text under the cursor in the background colour.
    static let kitty = Catalog(
        file: Paths.appFile(named: "kitty"),
        tables: [
            CatalogTable(
                name: "font", about: "kitty's font.",
                settings: [
                    CatalogSetting(
                        "family", "The font's family name, such as \"CaskaydiaCove Nerd Font Mono\".", .text(.plain),
                        [kitty("font_family")]),
                    CatalogSetting(
                        "size_pt", "The font's size.", .number(.pt, kittyFontSizes, decimal: false),
                        [kitty("font_size")]),
                ]),
            CatalogTable(
                name: "colors", about: "kitty's colours for its text, selection, cursor, links and tabs.",
                settings: [
                    CatalogSetting(
                        "text", "The text and the background.", .colorPairKeys,
                        [kittyColor("foreground"), kittyColor("background")]),
                    CatalogSetting(
                        "selection", "Selected text and its background.", .colorPairKeys,
                        [kittyColor("selection_foreground"), kittyColor("selection_background")]),
                    CatalogSetting("cursor", "The cursor.", .color, [kittyColor("cursor")]),
                    CatalogSetting("links", "Links under the pointer.", .color, [kittyColor("url_color")]),
                    CatalogSetting(
                        "active_tab", "The title of the tab you're in.", .colorPairKeys,
                        [kittyColor("active_tab_foreground"), kittyColor("active_tab_background")]),
                    CatalogSetting(
                        "inactive_tab", "The titles of the other tabs.", .colorPairKeys,
                        [kittyColor("inactive_tab_foreground"), kittyColor("inactive_tab_background")]),
                    CatalogSetting(
                        "mark", "Text kitty marks, such as with its mark commands.", .colorPairKeys,
                        [kittyColor("mark1_foreground"), kittyColor("mark1_background")]),
                ]),
            CatalogTable(
                name: "colors.normal", about: "The eight terminal colours programs use.",
                settings: kittyPalette(from: 0, "The terminal colour")),
            CatalogTable(
                name: "colors.bright", about: "The bright versions of the eight terminal colours.",
                settings: kittyPalette(from: terminalColors.count, "The bright version of")),
            CatalogTable(
                name: "window", about: "kitty's windows: their layout, margins, scrollback and closing.",
                settings: [
                    CatalogSetting(
                        "layouts",
                        "The layouts kitty may arrange the windows of a tab in, the first one when a tab opens.",
                        .parts(
                            ["splits", "tall", "fat", "grid", "horizontal", "vertical", "stack"].map {
                                CatalogValue.Part($0, $0)
                            }, join: ","), [kitty("enabled_layouts")]),
                    CatalogSetting(
                        "margin_pt", "The space around each window.", .number(.pt, kittyMargins, decimal: false),
                        [kitty("window_margin_width")]),
                    CatalogSetting(
                        "focus_follows_mouse", "Whether the window under the pointer gets the focus.", .flag,
                        [kitty("focus_follows_mouse")]),
                    CatalogSetting(
                        "scrollback_lines", "How many lines kitty keeps that have scrolled out of the window.",
                        .count(kittyScrollback), [kitty("scrollback_lines")]),
                    CatalogSetting(
                        "confirm_close",
                        "When closing a kitty window asks first: never, always, or when a program other than the "
                            + "shell is running in it.",
                        .choice([
                            .word("never", .integer(0)), .word("always", .integer(1)),
                            .word("when_running", .integer(-1)),
                        ]), [kitty("confirm_os_window_close")]),
                ]),
            CatalogTable(
                name: "shortcuts", about: "The keys that run kitty's actions.",
                settings: [
                    kittyAction("previous_tab", "Goes to the tab on the left.", "previous_tab"),
                    kittyAction("next_tab", "Goes to the tab on the right.", "next_tab"),
                    kittyAction(
                        "split_window", "Opens a new window beside the one you're in, in the splits layout.",
                        "launch --location=vsplit"),
                    kittyAction(
                        "close_window",
                        "Closes the window you're in, asking first when a program other than the shell runs in it.",
                        "close_window_with_confirmation ignore-shell"),
                ]),
            CatalogTable(
                name: "bell", about: "What kitty does when a program rings the bell.",
                settings: [
                    CatalogSetting(
                        "sound", "Whether kitty plays a sound.", .flag, [kitty("enable_audio_bell")])
                ]),
        ],
        always: [
            Catalog.Always(target: kitty("allow_remote_control"), value: .string(Kitten.remoteControl)),
            Catalog.Always(target: kitty("listen_on"), value: .string(Kitten.listenOn)),
            Catalog.Always(target: kittyColor("cursor_text_color"), value: .string("background")),
        ])

    // MARK: - newsboat

    /// A setting in newsboat's `config`.
    private static func newsboat(_ key: String) -> CatalogSetting.Target {
        .file([newsboatSettings, key])
    }

    /// The tables newsboat's files are written from: the settings, the shortcuts, each written with
    /// `bind-key`, the articles it ignores, and the feeds.
    static let newsboatSettings = "settings"
    /// The block of shortcuts.
    static let newsboatShortcuts = "keybindings"
    /// The block of articles newsboat ignores.
    static let newsboatIgnored = "ignore_articles"
    /// The feeds.
    static let newsboatFeeds = "feeds"

    /// The longest newsboat waits between reloads, any number of minutes, and the most feeds it
    /// reloads or files it downloads at once, any number.
    private static let anyNumber = 1...Int.max

    /// The command newsboat opens a link with: `open` with the app's bundle ID, and the link.
    private static let newsboatBrowser = (before: "open -b ", after: " %u")
    /// The command newsboat shows a notification with, which it gives the text.
    private static let newsboatNotifier = "terminal-notifier -title 'Newsboat' -message"
    /// What newsboat's download folder takes after it: a folder for each feed, by its name.
    private static let newsboatFeedFolder = "/%n"

    /// How newsboat names a shortcut: a letter, digit or sign as it is, shift with a letter as the
    /// capital, ctrl with a letter as `^` and the capital, and its own names for other keys.
    private static let newsboatShortcut = ShortcutStyle.text(
        names: [:], fn: nil, joiner: "+",
        keys: [
            "return": "ENTER", "escape": "ESC", "tab": "TAB", "delete": "BACKSPACE", "left": "LEFT", "right": "RIGHT",
            "up": "UP", "down": "DOWN", "home": "HOME", "end": "END", "page_up": "PPAGE", "page_down": "NPAGE",
            "minus": "-", "equal": "=", "open_bracket": "[", "close_bracket": "]", "backslash": "\\",
            "semicolon": ";", "quote": "'", "grave": "`", "comma": ",", "period": ".", "slash": "/",
        ].merging(functionKeys) { first, _ in first },
        whole: letterShortcuts)

    /// The function keys newsboat takes, by number.
    private static let functionKeyNumbers = 1...12
    /// newsboat's names of the function keys, such as `F1` for f1.
    private static let functionKeys = Dictionary(
        uniqueKeysWithValues: functionKeyNumbers.map { ("f\($0)", "F\($0)") })

    /// shift and ctrl with each letter, as newsboat names them: `J` and `^J`.
    private static let letterShortcuts = Dictionary(
        uniqueKeysWithValues: "abcdefghijklmnopqrstuvwxyz".flatMap { letter in
            [("shift+\(letter)", letter.uppercased()), ("ctrl+\(letter)", "^" + letter.uppercased())]
        })

    /// The setting `name` in `[shortcuts]`, which does `about` by running newsboat's `action`.
    private static func newsboatAction(_ name: String, _ about: String, _ action: String) -> CatalogSetting {
        CatalogSetting(
            name, about, .shortcutKeys(newsboatShortcut),
            [.fileKeys(table: [newsboatShortcuts], value: .string(action))])
    }

    /// The columns of newsboat's list of feeds.
    private static let feedColumns = [
        CatalogValue.Part("number", "%4i"), CatalogValue.Part("unread_mark", "%n"),
        CatalogValue.Part("counts", "%11u"), CatalogValue.Part("title", "%t"),
    ]

    /// The columns of newsboat's list of articles. `feed` shows only in lists of articles from
    /// several feeds.
    private static let articleColumns = [
        CatalogValue.Part("number", "%4i"), CatalogValue.Part("flags", "%f"), CatalogValue.Part("date", "%D"),
        CatalogValue.Part("feed", "%?T?|%-17T|?"), CatalogValue.Part("author", "%a"),
        CatalogValue.Part("title", "%t"),
    ]

    /// The parts of a date newsboat shows.
    private static let dateParts = [
        CatalogValue.Part("weekday", "%a"), CatalogValue.Part("day", "%d"), CatalogValue.Part("month", "%b"),
        CatalogValue.Part("month_number", "%m"), CatalogValue.Part("year", "%Y"),
        CatalogValue.Part("time", "%H:%M"),
    ]

    /// `apps/newsboat.toml`.
    static let newsboat = Catalog(
        file: Paths.appFile(named: "newsboat"),
        tables: [
            CatalogTable(
                name: "shortcuts", about: "The keys that run newsboat's actions.",
                settings: [
                    newsboatAction("down", "Goes to the next line.", "down"),
                    newsboatAction("up", "Goes to the line before.", "up"),
                    newsboatAction("first_item", "Goes to the first line.", "home"),
                    newsboatAction("last_item", "Goes to the last line.", "end"),
                    newsboatAction("next_feed", "Shows the articles of the next feed.", "next-feed articlelist"),
                    newsboatAction(
                        "previous_feed", "Shows the articles of the feed before.", "prev-feed articlelist"),
                    newsboatAction("open", "Opens the feed or article on the line.", "open"),
                    newsboatAction("close", "Goes back to the list before, or quits from the list of feeds.", "quit"),
                ]),
            CatalogTable(
                name: "browser", about: "The app newsboat opens links in.",
                settings: [
                    CatalogSetting(
                        "app", "The app's bundle ID.",
                        .app(before: newsboatBrowser.before, after: newsboatBrowser.after), [newsboat("browser")])
                ]),
            CatalogTable(
                name: "reload", about: "When and how newsboat fetches new articles.",
                settings: [
                    CatalogSetting(
                        "on_startup", "Whether newsboat fetches every feed when it opens.", .flag,
                        [newsboat("refresh-on-startup")]),
                    CatalogSetting(
                        "auto_reload", "Whether newsboat fetches the feeds by itself, every interval_minutes.", .flag,
                        [newsboat("auto-reload")]),
                    CatalogSetting(
                        "interval_minutes", "How long newsboat waits between fetching the feeds by itself.",
                        .minutes(anyNumber), [newsboat("reload-time")]),
                    CatalogSetting(
                        "parallel_feeds", "How many feeds newsboat fetches at once.", .count(anyNumber),
                        [newsboat("reload-threads")]),
                    CatalogSetting(
                        "only_visible_feeds", "Whether newsboat fetches only the feeds the list shows.", .flag,
                        [newsboat("reload-only-visible-feeds")]),
                ]),
            CatalogTable(
                name: "lists", about: "What newsboat's lists of feeds and articles show, and in what order.",
                settings: [
                    CatalogSetting(
                        "feed_columns", "The columns of the list of feeds, in order.", .parts(feedColumns, join: " "),
                        [newsboat("feedlist-format")]),
                    CatalogSetting(
                        "article_columns", "The columns of a list of articles, in order.",
                        .parts(articleColumns, join: " "), [newsboat("articlelist-format")]),
                    CatalogSetting(
                        "date_parts", "The parts of an article's date, in order.", .parts(dateParts, join: " "),
                        [newsboat("datetime-format")]),
                    CatalogSetting(
                        "sort_feeds_by", "The order of the list of feeds.",
                        .choice([
                            .word("none", .string("none")), .word("title", .string("title")),
                            .word("first_tag", .string("firsttag")),
                            .word("article_count", .string("articlecount")),
                            .word("unread_count", .string("unreadarticlecount")),
                            .word("last_updated", .string("lastupdated")),
                        ]), [newsboat("feed-sort-order")]),
                    CatalogSetting(
                        "show_read_feeds", "Whether the list of feeds shows feeds with no unread articles.", .flag,
                        [newsboat("show-read-feeds")]),
                    CatalogSetting(
                        "show_read_articles", "Whether a list of articles shows the ones you've read.", .flag,
                        [newsboat("show-read-articles")]),
                ]),
            CatalogTable(
                name: "downloads", about: "Where podboat, newsboat's downloader, saves podcasts.",
                settings: [
                    CatalogSetting(
                        "folder", "The folder, which gets a folder for each feed, by the feed's name.",
                        .path(then: newsboatFeedFolder), [newsboat("download-path")]),
                    CatalogSetting(
                        "max_at_once", "How many files podboat downloads at once.", .count(anyNumber),
                        [newsboat("max-downloads")]),
                ]),
            CatalogTable(
                name: "notifications", about: "Whether newsboat tells you about new articles.",
                settings: [
                    CatalogSetting(
                        "enabled", "Whether newsboat shows a notification and sets the terminal's title.",
                        .combinedFlag(
                            on: [.set(.string(newsboatNotifier)), .set(.boolean(true))],
                            off: [.remove, .set(.boolean(false))]),
                        [newsboat("notify-program"), newsboat("notify-screen")]),
                    CatalogSetting(
                        "after_every_reload", "Whether newsboat notifies after every fetch, even with nothing new.",
                        .flag, [newsboat("notify-always")]),
                ]),
            CatalogTable(
                name: "quit", about: "What newsboat does when it quits.",
                settings: [
                    CatalogSetting(
                        "confirm", "Whether newsboat asks before it quits.", .flag, [newsboat("confirm-exit")]),
                    CatalogSetting(
                        "clean_up", "Whether newsboat removes deleted articles from its cache.", .flag,
                        [newsboat("cleanup-on-quit")]),
                ]),
            CatalogTable(
                name: "ignored_articles", about: "Articles newsboat leaves out, by feed.",
                data: CatalogData(
                    keys: "a feed's address, or \"*\" for every feed",
                    values: "a filter in newsboat's filter language, or a list of them, such as 'link =~ \"/shorts/\"'",
                    into: [newsboatIgnored])),
            CatalogTable(
                name: "feeds", about: "The feeds newsboat follows, by title.",
                data: CatalogData(
                    keys: "a feed's title",
                    values: "the feed's address, or a table of its url and a list of tags",
                    into: [newsboatFeeds])),
        ])
}
