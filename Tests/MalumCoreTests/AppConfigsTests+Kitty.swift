import Testing

@testable import MalumCore

/// kitty's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    /// What Malum always writes in kitty.conf: the cursor's text colour, then the socket.
    private static let kittyAlways =
        "cursor_text_color background\n\nallow_remote_control socket-only\nlisten_on unix:/tmp/kitty\n"

    @Test func kittyWritesColoursSettingsAndShortcutsInBlocks() throws {
        let (files, problems) = try read(
            """
            [font]
            family = "Menlo"
            size_pt = 14

            [colors]
            text = { fg = "#f8f8f2", bg = "#282a36" }
            cursor = "#f8f8f2"

            [colors.normal]
            black = "#21222c"
            white = "#f8f8f2"

            [colors.bright]
            red = "#ff6e6e"

            [window]
            layouts = ["splits", "stack"]
            confirm_close = "when_running"
            margin_pt = 4

            [shortcuts]
            next_tab = ["cmd+l", "cmd+k"]
            split_window = "cmd+option+return"
            """, app: "kitty")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/kitty/kitty.conf",
                    Self.header(of: "kitty") + "background #282a36\ncolor0 #21222c\ncolor7 #f8f8f2\ncolor9 #ff6e6e\n"
                        + "cursor #f8f8f2\ncursor_text_color background\nforeground #f8f8f2\n\n"
                        + "allow_remote_control socket-only\nconfirm_os_window_close -1\n"
                        + "enabled_layouts splits,stack\nfont_family Menlo\nfont_size 14\n"
                        + "listen_on unix:/tmp/kitty\nwindow_margin_width 4\n\n"
                        + "map alt+cmd+enter launch --location=vsplit\nmap cmd+k next_tab\nmap cmd+l next_tab\n")
            ])
    }

    @Test func kittyWithoutSettingsStillListensOnItsSocket() throws {
        let (files, _) = try read("", app: "kitty")
        #expect(
            files == [AppFile(".config/kitty/kitty.conf", Self.header(of: "kitty") + Self.kittyAlways)])
    }

    @Test func kittysWrongValuesAndOldTablesAreProblems() throws {
        let (_, problems) = try read(
            """
            [settings]
            font_size = 14

            [colors]
            text = { fg = "#f8f8f2" }
            purple = "#bd93f9"

            [colors.normal]
            color3 = "#f1fa8c"

            [shortcuts]
            next_tab = "fn+l"
            """, app: "kitty")
        #expect(
            problems == [
                Message(.warn, "unknown table settings"),
                Message(.warn, "unknown setting colors.purple"),
                Message(
                    .error,
                    MessageText(
                        "colors.text should be a table with a colour fg and a colour bg, such as "
                            + "{ fg = \"#f8f8f2\", bg = \"#282a36\" }")),
                Message(.warn, "unknown setting colors.normal.color3"),
                Message(
                    .error,
                    MessageText(
                        "shortcuts.next_tab should be a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, "
                            + "then a key, joined by +, such as \"ctrl+option+k\", or a list of them")),
            ])
    }

}
