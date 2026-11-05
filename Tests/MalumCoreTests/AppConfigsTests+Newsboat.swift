import Testing

@testable import MalumCore

/// newsboat's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func newsboatWritesConfigAndFeeds() throws {
        let (files, problems) = try read(
            """
            [settings]
            auto-reload = true
            browser = "open %u"
            reload-time = 60

            [keybindings]
            J = "next-feed articlelist"

            [ignore_articles]
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
                    Self.header(of: "newsboat") + "auto-reload yes\nbrowser \"open %u\"\nreload-time 60\n\n"
                        + "bind-key J next-feed articlelist\n\n"
                        + "ignore-article * \"title =~ \\\"sponsored\\\"\"\n"
                        + "ignore-article * \"author = \\\"bot\\\"\"\n"),
                AppFile(
                    ".config/newsboat/urls",
                    Self.header(of: "newsboat") + "https://apple.example/rss \"tech\" \"mac os\" \"~Apple\"\n"
                        + "https://zebra.example/feed.xml \"~zebra\"\n"),
            ])
    }

    @Test func newsboatWithoutFeedsWritesNoUrlsFile() throws {
        let (files, _) = try read("", app: "newsboat")
        #expect(files == [AppFile(".config/newsboat/config", Self.header(of: "newsboat"))])
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
