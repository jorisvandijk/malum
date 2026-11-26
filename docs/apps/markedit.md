<!-- Made from the markedit catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# markedit settings reference

Every setting `apps/markedit.toml` takes, by table. Each one has a name you can read, and Malum writes what markedit keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[appearance]`

How MarkEdit looks. MarkEdit's settings, General and Editor.

### `mode`

Light, dark, or following macOS.

- Value: "system", "light" or "dark"
- Writes: `app.cyan.markedit` `general.appearance`

### `light_theme`

The theme in light mode, by its name in MarkEdit's settings, such as "github-light".

- Value: text that isn't empty
- Writes: `app.cyan.markedit` `editor.light-theme`

### `dark_theme`

The theme in dark mode, such as "dracula".

- Value: text that isn't empty
- Writes: `app.cyan.markedit` `editor.dark-theme`

## `[font]`

The editor's font.

### `name`

The font's PostScript name, as Font Book shows it, such as "CaskaydiaCoveNFM-Regular".

- Value: text that isn't empty
- Writes: `app.cyan.markedit` `editor.font-style`

### `size_pt`

The font's size.

- Value: a number of points from 6 to 100
- Writes: `app.cyan.markedit` `editor.font-size`

## `[editor]`

How the editor works.

### `wrap_lines`

Whether a line longer than the window wraps, at a word, or runs on.

- Value: "never" or "at_words"
- Writes: `app.cyan.markedit` `editor.line-wrapping`

## `[updates]`

Whether MarkEdit looks for new versions.

### `auto_check`

Whether MarkEdit checks for new versions and says when there is one.

- Value: true or false
- Writes: `$HOME/Library/Containers/app.cyan.markedit/Data/Documents/settings.json` `general.updateBehavior`

## `[css]`

CSS MarkEdit adds to the editor, such as a font for code blocks.

### `text`

The CSS, as it is.

- Value: text that isn't empty
- Writes: `$HOME/Library/Containers/app.cyan.markedit/Data/Documents/editor.css` `text`
