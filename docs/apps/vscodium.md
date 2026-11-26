<!-- Made from the vscodium catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# vscodium settings reference

Every setting `apps/vscodium.toml` takes, by table. Each one has a name you can read, and Malum writes what vscodium keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[appearance]`

How VSCodium looks.

### `theme`

The colour theme, by the name VSCodium's theme picker shows, such as "Dracula Theme".

- Value: text that isn't empty
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `workbench.colorTheme`

## `[font]`

The font of the editor and the terminal.

### `family`

The font's family name, such as "CaskaydiaCove Nerd Font Mono". Malum writes it with monospace after it, so a missing font still shows as one.

- Value: text that isn't empty
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `editor.fontFamily`, `$HOME/Library/Application Support/VSCodium/User/settings.json` `terminal.integrated.fontFamily`

### `size_pt`

The font's size.

- Value: a number of points from 6 to 100
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `editor.fontSize`, `$HOME/Library/Application Support/VSCodium/User/settings.json` `terminal.integrated.fontSize`

### `ligatures`

Whether the editor joins letters the font has ligatures for, such as -> and !=.

- Value: true or false
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `editor.fontLigatures`

## `[editor]`

How the editor works.

### `auto_save`

When the editor saves a changed file by itself: after a short delay, when it loses focus, when the window does, or never.

- Value: "off", "after_delay", "on_focus_change" or "on_window_change"
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `files.autoSave`

## `[updates]`

Whether VSCodium and its extensions look for new versions.

### `auto_check`

Whether VSCodium checks for and downloads new versions of itself.

- Value: true or false
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `update.mode`

### `auto_check_extensions`

Whether VSCodium checks for new versions of its extensions.

- Value: true or false
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `extensions.autoCheckUpdates`

## `[privacy]`

What VSCodium sends about how it's used and when it crashes.

### `telemetry`

What VSCodium and its extensions may report: nothing, crashes, errors, or all usage.

- Value: "off", "crashes", "errors" or "all"
- Writes: `$HOME/Library/Application Support/VSCodium/User/settings.json` `telemetry.telemetryLevel`

### `send_crash_reports`

Whether VSCodium sends a report when it crashes.

- Value: true or false
- Writes: `$HOME/.vscode-oss/argv.json` `enable-crash-reporter`
