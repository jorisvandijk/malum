<!-- Made from the kitty catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# kitty settings reference

Every setting `apps/kitty.toml` takes, by table. Each one has a name you can read, and Malum writes what kitty keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

Malum always writes these, which have no setting:

- `$HOME/.config/kitty/kitty.conf` `allow_remote_control`: `"socket-only"`
- `$HOME/.config/kitty/kitty.conf` `listen_on`: `"unix:/tmp/kitty"`
- `$HOME/.config/kitty/kitty.conf` `cursor_text_color`: `"background"`

## `[font]`

kitty's font.

### `family`

The font's family name, such as "CaskaydiaCove Nerd Font Mono".

- Value: text that isn't empty
- Writes: `$HOME/.config/kitty/kitty.conf` `font_family`

### `size_pt`

The font's size.

- Value: a number of points from 4 to 200
- Writes: `$HOME/.config/kitty/kitty.conf` `font_size`

## `[colors]`

kitty's colours for its text, selection, cursor, links and tabs.

### `text`

The text and the background.

- Value: a table with a colour fg and a colour bg, such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/kitty/kitty.conf` `foreground`, `$HOME/.config/kitty/kitty.conf` `background`

### `selection`

Selected text and its background.

- Value: a table with a colour fg and a colour bg, such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/kitty/kitty.conf` `selection_foreground`, `$HOME/.config/kitty/kitty.conf` `selection_background`

### `cursor`

The cursor.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `cursor`

### `links`

Links under the pointer.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `url_color`

### `active_tab`

The title of the tab you're in.

- Value: a table with a colour fg and a colour bg, such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/kitty/kitty.conf` `active_tab_foreground`, `$HOME/.config/kitty/kitty.conf` `active_tab_background`

### `inactive_tab`

The titles of the other tabs.

- Value: a table with a colour fg and a colour bg, such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/kitty/kitty.conf` `inactive_tab_foreground`, `$HOME/.config/kitty/kitty.conf` `inactive_tab_background`

### `mark`

Text kitty marks, such as with its mark commands.

- Value: a table with a colour fg and a colour bg, such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/kitty/kitty.conf` `mark1_foreground`, `$HOME/.config/kitty/kitty.conf` `mark1_background`

## `[colors.normal]`

The eight terminal colours programs use.

### `black`

The terminal colour black.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color0`

### `red`

The terminal colour red.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color1`

### `green`

The terminal colour green.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color2`

### `yellow`

The terminal colour yellow.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color3`

### `blue`

The terminal colour blue.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color4`

### `magenta`

The terminal colour magenta.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color5`

### `cyan`

The terminal colour cyan.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color6`

### `white`

The terminal colour white.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color7`

## `[colors.bright]`

The bright versions of the eight terminal colours.

### `black`

The bright version of black.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color8`

### `red`

The bright version of red.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color9`

### `green`

The bright version of green.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color10`

### `yellow`

The bright version of yellow.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color11`

### `blue`

The bright version of blue.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color12`

### `magenta`

The bright version of magenta.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color13`

### `cyan`

The bright version of cyan.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color14`

### `white`

The bright version of white.

- Value: a colour, # and six lowercase hexadecimal digits, such as "#f8f8f2"
- Writes: `$HOME/.config/kitty/kitty.conf` `color15`

## `[window]`

kitty's windows: their layout, margins, scrollback and closing.

### `layouts`

The layouts kitty may arrange the windows of a tab in, the first one when a tab opens.

- Value: a list of at least one of "splits", "tall", "fat", "grid", "horizontal", "vertical" or "stack"
- Writes: `$HOME/.config/kitty/kitty.conf` `enabled_layouts`

### `margin_pt`

The space around each window.

- Value: a number of points from 0 to 100
- Writes: `$HOME/.config/kitty/kitty.conf` `window_margin_width`

### `focus_follows_mouse`

Whether the window under the pointer gets the focus.

- Value: true or false
- Writes: `$HOME/.config/kitty/kitty.conf` `focus_follows_mouse`

### `scrollback_lines`

How many lines kitty keeps that have scrolled out of the window.

- Value: a whole number, 0 or more
- Writes: `$HOME/.config/kitty/kitty.conf` `scrollback_lines`

### `confirm_close`

When closing a kitty window asks first: never, always, or when a program other than the shell is running in it.

- Value: "never", "always" or "when_running"
- Writes: `$HOME/.config/kitty/kitty.conf` `confirm_os_window_close`

## `[shortcuts]`

The keys that run kitty's actions.

### `previous_tab`

Goes to the tab on the left.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/kitty/kitty.conf`, a key per shortcut, set to `"previous_tab"`

### `next_tab`

Goes to the tab on the right.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/kitty/kitty.conf`, a key per shortcut, set to `"next_tab"`

### `split_window`

Opens a new window beside the one you're in, in the splits layout.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/kitty/kitty.conf`, a key per shortcut, set to `"launch --location=vsplit"`

### `close_window`

Closes the window you're in, asking first when a program other than the shell runs in it.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/kitty/kitty.conf`, a key per shortcut, set to `"close_window_with_confirmation ignore-shell"`

## `[bell]`

What kitty does when a program rings the bell.

### `sound`

Whether kitty plays a sound.

- Value: true or false
- Writes: `$HOME/.config/kitty/kitty.conf` `enable_audio_bell`
