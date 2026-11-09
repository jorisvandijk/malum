<!-- Made from the modules' schemas by `swift run MalumDocs`. Edit the schemas, not this page. -->

# Config reference

Every setting `malum.toml` takes, by module. Each module's settings go in a table named after the module, such as `[system_config]`. A module is off until its table sets `enabled = true`. A setting that's left out takes its default, when it has one.

A module's settings can go in a file of their own in dots instead, next to `malum.toml` and named after the module, such as `system_config.toml`. That file holds the same settings without the table around them. `enabled` always stays in `malum.toml`, and a module's settings go in one of the two places, never both.

## `clipboard`

A history of what you copy, in the popup. See [clipboard history](clipboard.md).

### `clipboard.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `clipboard.paste`

Pastes an entry into the app below when you pick it, besides putting it on the clipboard.

- Value: true or false
- Default: `true`

### `clipboard.size`

How many copies the history keeps, at least 1.

- Value: a whole number
- Default: `300`

## `keyboard`

The hyper key, key remaps and shortcuts, set in `keyboard.toml`. See [keyboard](keyboard.md).

### `keyboard.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

## `launcher`

A popup with every app, to search and start one. See [launcher](launcher.md).

### `launcher.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

## `samba`

Samba shares mounted under `/Volumes`. See [Samba](samba.md).

### `samba.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `samba.server`

The servers, one `[[server]]` each, with `name`, `host`, `user` and `shares`, the list of shares to mount.

- Value: a list of tables

## `screenshots`

Screenshots you crop and draw on before they're saved. See [screenshots](screenshots.md).

### `screenshots.colors`

The quick colors in the toolbar, 1 to 7 as "#rrggbb". The first is the color you start with.

- Value: a list of text in quotes
- Default: `["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#007aff", "#ffffff", "#000000"]`

### `screenshots.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `screenshots.folder`

The folder screenshots are saved in.

- Value: text in quotes
- Default: `"~/Documents"`

## `system_config`

Makes the Mac match dots when you run `malum run`, installing what `packages.toml` lists, writing the app config files and preferences in `apps/` and setting the macOS settings in `macos.toml`. At the end of the run, Malum updates itself. Nothing happens in the background: the app only reads the switch, and `malum run` does the work.

### `system_config.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `system_config.release_apps`

The folder apps from GitHub releases are installed in.

- Value: text in quotes
- Default: `"/Applications"`

### `system_config.release_programs`

The folder programs from GitHub releases are installed in.

- Value: text in quotes
- Default: `"~/.local/bin"`

## `window_manager`

Run or raise apps, windows filling the screen, and floating windows. See [window manager](window-manager.md).

### `window_manager.block_hide_minimize`

Swallows cmd+H, cmd+M and cmd+option+M, which would hide an app or minimise a window.

- Value: true or false
- Default: `true`

### `window_manager.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `window_manager.float`

Apps whose windows are left alone, each with `app` (a bundle ID) and an optional `title`, a pattern that only matching windows float by.

- Value: a list of tables

### `window_manager.frame`

The part of the screen windows fill: "visible" (below the menu bar and outside the Dock) or "full" (the whole screen).

- Value: text in quotes
- Default: `"visible"`
