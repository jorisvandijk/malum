<!-- Made from the command-x catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# command-x settings reference

Every setting `apps/command-x.toml` takes, by table. Each one has a name you can read, and Malum writes what command-x keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

Malum always writes these, which have no setting:

- `com.sindresorhus.Command-X` `newMethod`: `true`

## `[shortcuts]`

The keys that cut and paste files in Finder.

### `cut`

Cuts the selected files.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k"
- Writes: `com.sindresorhus.Command-X` `KeyboardShortcuts_cut`

### `paste`

Moves the cut files here.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k"
- Writes: `com.sindresorhus.Command-X` `KeyboardShortcuts_paste`
