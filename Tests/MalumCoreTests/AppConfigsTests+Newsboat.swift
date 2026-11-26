import Testing

@testable import MalumCore

/// newsboat's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func newsboatWritesConfigAndFeeds() throws {
        let (files, problems) = try read(
            """
            [shortcuts]
            down = "j"
            next_feed = "shift+j"
            close = ["h", "ctrl+q"]

            [browser]
            app = "net.librewolf.librewolf"

            [reload]
            auto_reload = true
            interval_minutes = 60

            [lists]
            article_columns = ["number", "flags", "date", "feed", "title"]
            date_parts = ["month", "day"]
            sort_feeds_by = "last_updated"

            [downloads]
            folder = "$HOME/Downloads/newsboat"

            [notifications]
            enabled = true
            """, app: "newsboat")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/newsboat/config",
                    Self.header(of: "newsboat") + "articlelist-format \"%4i %f %D %?T?|%-17T|? %t\"\n"
                        + "auto-reload yes\nbrowser \"open -b net.librewolf.librewolf %u\"\n"
                        + "datetime-format \"%b %d\"\ndownload-path \"/Users/test/Downloads/newsboat/%n\"\n"
                        + "feed-sort-order \"lastupdated\"\n"
                        + "notify-program \"terminal-notifier -title 'Newsboat' -message\"\nnotify-screen yes\n"
                        + "reload-time 60\n\n"
                        + "bind-key J next-feed articlelist\nbind-key ^Q quit\nbind-key h quit\nbind-key j down\n")
            ])
    }

    @Test func newsboatWritesIgnoredArticlesAndFeedsAsTheyAre() throws {
        let (files, problems) = try read(
            """
            [ignored_articles]
            "*" = ["title =~ \\"sponsored\\"", "author = \\"bot\\""]

            [feeds]
            zebra = "https://zebra.example/feed.xml"
            Apple = { url = "https://apple.example/rss", tags = ["tech", "mac os"] }
            """, app: "newsboat")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/newsboat/config",
                    Self.header(of: "newsboat") + "ignore-article * \"title =~ \\\"sponsored\\\"\"\n"
                        + "ignore-article * \"author = \\\"bot\\\"\"\n"),
                AppFile(
                    ".config/newsboat/urls",
                    Self.header(of: "newsboat") + "https://apple.example/rss \"tech\" \"mac os\" \"~Apple\"\n"
                        + "https://zebra.example/feed.xml \"~zebra\"\n"),
            ])
    }

    @Test func newsboatWithoutNotificationsWritesNoProgram() throws {
        let (files, _) = try read("[notifications]\nenabled = false\n", app: "newsboat")
        #expect(files == [AppFile(".config/newsboat/config", Self.header(of: "newsboat") + "notify-screen no\n")])
    }

    @Test func newsboatWithoutFeedsWritesNoUrlsFile() throws {
        let (files, _) = try read("", app: "newsboat")
        #expect(files == [AppFile(".config/newsboat/config", Self.header(of: "newsboat"))])
    }

    @Test func newsboatsWrongValuesAndOldTablesAreProblems() throws {
        let (files, problems) = try read(
            """
            [settings]
            auto-reload = true

            [shortcuts]
            down = "cmd+j"

            [browser]
            app = "open -a LibreWolf"

            [lists]
            article_columns = ["number", "subject"]
            """, app: "newsboat")
        #expect(files == [AppFile(".config/newsboat/config", Self.header(of: "newsboat"))])
        #expect(
            problems == [
                Message(.warn, "unknown table settings"),
                Message(
                    .error,
                    MessageText(
                        "shortcuts.down should be a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then "
                            + "a key, joined by +, such as \"ctrl+option+k\", or a list of them")),
                Message(.error, "browser.app should be an app's bundle ID, such as \"net.librewolf.librewolf\""),
                Message(
                    .error,
                    MessageText(
                        "lists.article_columns should be a list of at least one of \"number\", \"flags\", \"date\", "
                            + "\"feed\", \"author\" or \"title\"")),
            ])
    }

    @Test func wrongFeedsAreErrors() throws {
        let (files, problems) = try read(
            """
            [feeds]
            Spaced = "https://a.example/ feed"
            Empty = ""
            Number = 1
            Tagged = { url = "https://b.example/", tags = "tech" }
            Extra = { url = "https://c.example/", colour = "red" }
            """, app: "newsboat")
        #expect(files.last?.text == Self.header(of: "newsboat") + "https://c.example/ \"~Extra\"\n")
        #expect(
            problems == [
                Message(.error, "feeds.Empty should be an address without spaces, or a table with url and tags"),
                Message(.warn, "unknown setting feeds.Extra.colour"),
                Message(.error, "feeds.Number should be an address without spaces, or a table with url and tags"),
                Message(.error, "feeds.Spaced should be an address without spaces, or a table with url and tags"),
                Message(.error, "feeds.Tagged.tags should be a list of text in quotes"),
            ])
    }
}
