# Menu bar

While the app runs, Malum's icon sits in the menu bar. It's the Malum apple while everything is fine, and a warning triangle while something needs attention.

Click the icon to open the menu. When all is well, it holds only actions:

- **Run** does what `malum run` does and shows what it reports in the popup, newest line at the top, as it goes. It doesn't ask for your password, so anything that needs sudo reports that it couldn't, and it doesn't update Malum. Run `malum run` in a terminal for those.
- **Inspect window**, while the window manager runs, waits for a click on a window and shows what the [window inspector](window-manager.md) finds, as the `inspect_window` key does.
- **Show log** shows Malum's [log](log.md) of the last hour in the popup, newest line at the top.
- **Reload** reads `malum.toml` and the modules' own files again and restarts every module that's on, even ones whose settings didn't change. Use it when a module gets stuck, such as the hyper key. A notification says when it's done, or shows the first error. The first time, macOS asks whether Malum may show notifications. `malum reload` and saving a file only apply what changed.
- **About Malum** shows Malum's logo, version, maker and website.
- **Quit Malum**, also with ⌘Q while the menu is open. Quitting stops every module first, so what they changed, such as the hyper key, is undone.

With `terminal` set in `[system_config]` (see [config](config.md)), such as `terminal = "net.kovidgoyal.kitty"`, Run and Show log open in that terminal instead: Run as `malum run`, which can ask for your password and update Malum, and Show log as `malum log --last 1h`. A shell stays open when the command is done. With kitty running and listening on its socket (`allow_remote_control socket-only` and `listen_on unix:/tmp/kitty` in kitty.conf), they open as a new tab in it and kitty comes to the front. Otherwise they open a new kitty window.

In the popup, type to keep only the lines that hold the text, and press Escape to close it.

When something is wrong, each problem shows at the top of the menu, and picking it fixes it or shows where to look:

- Malum isn't [signed](signing.md) with its own certificate, so the modules stay off: shows the log.
- [Safe mode](safe-mode.md) is on: **Leave safe mode** turns it off, so the modules start as `malum.toml` says.
- A module was kept off with `malum disable`: **Enable \<module\>** lets it run again.
- A module is missing a permission: an item for each one opens the page in System Settings where you grant it, as the [permissions page](permissions.md) explains. The module doesn't start until they're granted.
- A module failed or runs with problems: shows the log.
- A problem in `malum.toml` or a module's own file, with the same tags and line numbers as in the terminal: opens `malum.toml`. When the file doesn't exist, it opens the dots folder in Finder instead. When Malum doesn't know where dots is yet, run `malum init` as the problem says.

Each module's status is in `malum status`.

The menu follows along: saving `malum.toml` or a module changing its status updates it straight away.
