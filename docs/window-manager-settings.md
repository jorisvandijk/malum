<!-- Made from the window_manager.toml catalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

# window_manager.toml reference

Every table and setting `window_manager.toml` takes. A setting you leave out takes its default. A name a table doesn't take gets a warning. See [window manager](window-manager.md) for how it works.

## `[windows]`

How windows fill the screen, and what apps may do with them.

### `frame`

The part of the screen windows fill: `visible` is below the menu bar and outside the Dock, `full` the whole screen.

- Value: "visible" or "full"

### `allow_hide_minimize`

Lets cmd+H, cmd+M and cmd+option+M hide an app or minimise a window. Left off, the window manager swallows them, since a hidden app or a minimised window leaves a gap.

- Value: true or false

### `split_step_percent`

How far `split_left`, `split_right`, `split_taller` and `split_shorter` move a border, in percent of the area. 5 when it's left out.

- Value: a whole number from 1 to 25

## `[floating_windows.<name>]`

Windows the window manager leaves alone.

- Names: what floats, such as "password_prompts"
- Each one needs every setting below but `title`.

### `app`

The app, by bundle ID.

- Value: an app's bundle ID, such as "net.librewolf.librewolf"

### `title`

A pattern for the window's title, such as "^Picture-in-Picture$": only windows whose title matches float. Left out, every window of the app floats.

- Value: text that isn't empty
