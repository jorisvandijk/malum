<!-- Made from the keyboard.toml catalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

# keyboard.toml reference

Every table and setting `keyboard.toml` takes. A setting you leave out takes its default. A name a table doesn't take gets a warning. See [keyboard](keyboard.md) for how it works.

## `[hyper]`

The hyper key holds ctrl, option, cmd and shift down together while you hold it, so a shortcut such as hyper+k works in any app that lets you set one.

### `key`

The key that becomes the hyper key. Leave it out for no hyper key.

- Value: "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "caps_lock", "left_option", "right_option" or "right_command"

## `[remaps]`

Keys that type as another key, on every keyboard, while Malum runs. The hyper key can't be remapped.

- Keys: the key pressed, by its name, such as "caps_lock"
- Values: the key it types as, by its name, such as "escape"

## `[shortcuts]`

Shortcuts and what they do.

- Keys: a shortcut: modifiers `ctrl`, `option`, `cmd`, `shift` or `hyper` for all four, then a key name, joined by `+`, such as "hyper+b" or "ctrl+cmd+h"
- Values: what it does: an app's bundle ID, which the window manager runs or raises, or an action a module offers, such as "launcher"
