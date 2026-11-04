# Menu bar

While the app runs, Malum's icon sits in the menu bar. It's a leaf while everything is fine, and a warning triangle while something needs attention: a problem in `malum.toml`, a module that failed or runs with problems, or a module that's missing a permission.

Click the icon to open the menu. From top to bottom it shows:

- Malum's name and version.
- Each module with its status: `off`, `starting`, `running`, `degraded` or `failed` with the reason, or `needs` with the permissions it's missing. Under a module that's missing permissions, an item for each one opens the page in System Settings where you grant it.
- Every problem in `malum.toml`, with the same tags and line numbers as in the terminal, or `malum.toml has no problems`. Below it, **Open malum.toml** opens the file in its default app. When the file doesn't exist, **Show dots folder** opens the dots folder in Finder instead. When Malum doesn't know where dots is yet, run `malum init` as the problem says.
- **Reload malum.toml**, which does the same as `malum reload`.
- **Quit Malum**, also with ⌘Q while the menu is open.

The menu follows along: saving `malum.toml` or a module changing its status updates it straight away.
