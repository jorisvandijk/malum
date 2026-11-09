# Menu bar

While the app runs, Malum's icon sits in the menu bar. It's the Malum apple while everything is fine, and a warning triangle while something needs attention: Malum isn't signed with its own certificate, safe mode, a problem in `malum.toml`, a module that failed or runs with problems, or a module that's missing a permission.

Click the icon to open the menu. From top to bottom it shows:

- Malum's name and version.
- When Malum isn't [signed](signing.md) with its own certificate, why, and that the modules stay off.
- In [safe mode](safe-mode.md), why it's on, and **Leave safe mode**, which turns it off so the modules start as `malum.toml` says.
- Each module with its status: `off`, `starting`, `running`, `degraded` or `failed` with the reason, or `needs` with the permissions it's missing. A module that's missing permissions doesn't start until they're granted. Under it, an item for each one opens the page in System Settings where you grant it, as the [permissions page](permissions.md) explains. Below the modules, **Enable \<module\>** for each module kept off with `malum disable`.
- Every problem in `malum.toml`, with the same tags and line numbers as in the terminal, or `malum.toml has no problems`. Below it, **Open malum.toml** opens the file in its default app. When the file doesn't exist, **Show dots folder** opens the dots folder in Finder instead. When Malum doesn't know where dots is yet, run `malum init` as the problem says.
- **Reload malum.toml**, which does the same as `malum reload`.
- **Quit Malum**, also with ⌘Q while the menu is open. Quitting stops every module first, so what they changed, such as the hyper key, is undone.

The menu follows along: saving `malum.toml` or a module changing its status updates it straight away.
