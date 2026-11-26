@testable import MalumCore

/// The example of each file, which sets every key its tables take.
extension ConfigKeysDocsTests {
    /// A part of the docs: a page in `docs/`, or one section of it with its subsections.
    struct DocsPart: Sendable, CustomStringConvertible {
        /// The page, such as `keyboard.md`.
        let page: String
        /// The section's heading, or nil for the whole page.
        let heading: String?

        var description: String { heading.map { "\(page) › \($0)" } ?? page }
    }

    /// A file's example, how it's read and the parts of the docs that cover it.
    struct Example: Sendable {
        /// The file, as problems name it.
        let file: String
        /// The example.
        let text: String
        /// Where its keys have docs.
        let docs: [DocsPart]
        /// Reads `text` and gives the problems found.
        let read: @MainActor @Sendable (String) -> [ConfigProblem]
        /// Whether the key at a path has its docs on a generated page, and so isn't checked here.
        var generated: @Sendable ([String]) -> Bool = { _ in false }
    }

    /// Every file's example.
    static var examples: [Example] {
        [
            Example(
                file: Paths.macOSTOMLName, text: macOS,
                docs: [DocsPart(page: "macos-settings.md", heading: nil), systemConfig("macOS settings")],
                read: { MacOSSettings.read($0).problems },
                generated: { path in MacOSCatalog.tables.contains { $0.name == path.first } }),
            Example(
                file: Paths.packagesTOMLName, text: packages,
                docs: [systemConfig("packages.toml"), systemConfig("App Store apps"), systemConfig("GitHub releases")],
                read: { PackageList.read($0).problems }),
            Example(
                file: Paths.moduleTOMLName(KeyboardConfig.module), text: keyboard,
                docs: [DocsPart(page: "keyboard.md", heading: nil)], read: { KeyboardConfig.read($0).problems }),
            Example(
                file: Paths.webAppsTOMLName, text: webApps, docs: [systemConfig("Web apps")],
                read: { WebAppList.read($0).problems }),
        ] + AppConfigs.all.map(example(of:))
    }

    /// The section `heading` of `system-config.md`.
    private static func systemConfig(_ heading: String) -> DocsPart {
        DocsPart(page: "system-config.md", heading: heading)
    }

    /// The example of `app`'s file in `apps/`, whose docs are its own section, or the one on app
    /// preferences for an app that only has those.
    private static func example(of app: AppConfig) -> Example {
        let file = Paths.appFile(named: app.name)
        return Example(
            file: file, text: apps[app.name] ?? "",
            docs: [systemConfig(app.files.isEmpty ? "App preferences" : app.name)],
            read: { text in
                do throws(ConfigProblem) {
                    var reader = try TableReader(text, file: file)
                    _ = app.read(&reader)
                    return reader.problems
                } catch {
                    return [error]
                }
            })
    }

    /// `macos.toml`, without the curated tables: their page is made from the catalog.
    private static let macOS = """
        [preferences]
        [current_host]

        [hosts]
        nas = "192.168.1.5"

        [sudo]
        touch_id = true

        [power.battery]
        [power.charger]

        [apple_apps]
        remove = ["Chess"]

        [default_apps]
        browser = "org.mozilla.librewolf"
        video = "io.mpv"

        [computer]
        hostname = "macbook"
        boot_sound = false

        [display]
        resolution = "1710x1112"

        [screen_lock]
        delay = 0

        [startup]
        apps = ["com.if.Amphetamine"]

        [home_folders]
        show = ["Documents"]
        """

    /// `packages.toml`.
    private static let packages = """
        [homebrew]
        kitty = "cask"

        [app_store]
        xcode = 497799835

        [release.mpv]
        repo = "mpv-player/mpv"
        asset = "mpv.zip"
        """

    /// `keyboard.toml`.
    private static let keyboard = """
        [settings]
        hyper_key = "left_option"

        [remap]
        fn = "left_control"

        [hyper]
        f = "com.apple.finder"
        """

    /// `webapps.toml`.
    private static let webApps = """
        [Frigate]
        url = "http://192.168.1.5:5000"
        icon = "icons/frigate.png"
        """

    /// Each app's file in `apps/`, by the app's name.
    static let apps = [
        "amphetamine": "[preferences]",
        "command-x": "[preferences]",
        "cursorcerer": "[preferences]",
        "oversight": "[preferences]",
        "git": git,
        "kitty": "[theme]\n[settings]\n[keybindings]",
        "librewolf": libreWolf,
        "markedit": markEdit,
        "micro": "[settings]\n[bindings]\n[colorschemes]",
        "newsboat": newsboat,
        "ssh": "[hosts]",
        "vscodium": "[settings]\n[argv]\n[extensions]\nids = []",
        "zsh": zsh,
    ]

    /// `apps/git.toml`.
    private static let git = """
        [settings]
        [ignore]
        patterns = [".DS_Store"]
        [attributes]
        lines = ["*.png binary"]
        """

    /// `apps/librewolf.toml`.
    private static let libreWolf = """
        [settings]
        [policies]
        [user_chrome]
        text = "#alltabs-button { display: none !important; }"
        """

    /// `apps/markedit.toml`.
    private static let markEdit = """
        [preferences]
        [settings]
        [css]
        text = "body { margin: 0; }"
        [extensions]
        ids = []
        """

    /// `apps/newsboat.toml`.
    private static let newsboat = """
        [settings]
        [keybindings]
        [ignore_articles]
        [feeds.News]
        url = "https://example.com/feed.xml"
        tags = ["news"]
        """

    /// `apps/zsh.toml`.
    private static let zsh = """
        [environment]
        [aliases]
        [abbreviations]
        [global_abbreviations]
        [options]
        [functions]

        [homebrew]
        shellenv = true

        [path]
        prepend = ["$HOME/.local/bin"]

        [plugins]
        completion = true
        autosuggestions = true
        kitty_integration = true
        fzf = true
        syntax_highlighting = true
        zoxide = true
        zoxide_options = ["--cmd", "cd"]

        [history]
        size = 10000
        save = 10000
        file = "$HOME/.local/state/zsh/history"
        ignore_dups = true
        ignore_all_dups = true
        save_no_dups = true
        find_no_dups = true
        ignore_space = true
        expire_dups_first = true
        share = true
        extended = true

        [source]
        files = []

        [prompt]
        text = "%~ "
        right = "%T"
        """
}
