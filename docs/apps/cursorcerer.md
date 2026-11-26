<!-- Made from the cursorcerer catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# cursorcerer settings reference

Every setting `apps/cursorcerer.toml` takes, by table. Each one has a name you can read, and Malum writes what cursorcerer keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[shortcuts]`

The key that hides and shows the pointer.

### `toggle_pointer`

Hides the pointer, or shows it again.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k"
- Writes: `com.doomlaser.cursorcerer` `toggleCursorHotKey`

## `[pointer]`

When Cursorcerer hides the pointer and shows it again.

### `hide_after_seconds`

How long the pointer stays still before it hides.

- Value: a whole number of seconds from 1 to 3600
- Writes: `com.doomlaser.cursorcerer` `idleHide`

### `show_on_move`

Whether a hidden pointer shows again when it moves.

- Value: true or false
- Writes: `com.doomlaser.cursorcerer` `autoShow`
