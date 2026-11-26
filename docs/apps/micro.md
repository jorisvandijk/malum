<!-- Made from the micro catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# micro settings reference

Every setting `apps/micro.toml` takes, by table. Each one has a name you can read, and Malum writes what micro keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

Malum always writes these, which have no setting:

- `$HOME/.config/micro/settings.json` `colorscheme`: `"malum"`

## `[colors]`

micro's colours, each a text colour and a background, with an optional style. A part with no text colour uses the terminal's.

### `text`

Plain text, and the background of the whole editor.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `default`

### `comment`

Comments.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `comment`

### `identifier`

Names of functions and other things.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `identifier`

### `identifier_class`

Names of classes.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `identifier.class`

### `identifier_var`

Names of variables.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `identifier.var`

### `constant`

Constants, such as true and false.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `constant`

### `constant_number`

Numbers.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `constant.number`

### `constant_string`

Strings.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `constant.string`

### `symbol`

Operators and other symbols.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `symbol`

### `symbol_brackets`

Brackets.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `symbol.brackets`

### `symbol_tag`

Tags, such as HTML's.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `symbol.tag`

### `type`

Types.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `type`

### `type_keyword`

Keywords that make types, such as struct.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `type.keyword`

### `type_extended`

Other types some languages name.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `type.extended`

### `special`

Special characters, such as escapes in a string.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `special`

### `statement`

Statements, such as if and return.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `statement`

### `preprocessor`

Preprocessor lines, such as #include.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `preproc`

### `underlined`

Underlined text, such as links.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `underlined`

### `error`

Errors in the code.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `error`

### `todo`

TODO and FIXME in comments.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `todo`

### `diff_added`

The gutter mark of a line added since the last commit.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `diff-added`

### `diff_modified`

The gutter mark of a changed line.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `diff-modified`

### `diff_deleted`

The gutter mark where lines were removed.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `diff-deleted`

### `gutter_error`

The gutter mark of a line a linter finds an error in.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `gutter-error`

### `gutter_warning`

The gutter mark of a line a linter warns about.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `gutter-warning`

### `status_line`

The status line at the bottom.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `statusline`

### `tab_bar`

The tab bar at the top.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `tabbar`

### `indent_char`

The marks that show indents, with indentchar set.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `indent-char`

### `line_number`

Line numbers.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `line-number`

### `current_line_number`

The number of the line the cursor is on.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `current-line-number`

### `cursor_line`

The line the cursor is on.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `cursor-line`

### `color_column`

The column that marks the line length, with colorcolumn set.

- Value: a table with a colour fg (or none, for the default), an optional colour bg and an optional style "bold", "italic" or "underline", such as { fg = "#f8f8f2", bg = "#282a36" }
- Writes: `$HOME/.config/micro/colorschemes/malum.micro` `color-column`

## `[editor]`

How the editor works.

### `wrap_lines`

Whether a line longer than the window wraps, anywhere or at a word, or runs on past the edge.

- Value: "never", "anywhere" or "at_words"
- Writes: `$HOME/.config/micro/settings.json` `softwrap`, `$HOME/.config/micro/settings.json` `wordwrap`

## `[shortcuts]`

The keys that run micro's actions.

### `toggle_comment`

Comments out the selected lines, or the line the cursor is on, or back in.

- Value: a shortcut: modifiers cmd, ctrl, option, shift, fn or hyper, then a key, joined by +, such as "ctrl+option+k", or a list of them
- Writes: `$HOME/.config/micro/bindings.json`, a key per shortcut, set to `"lua:comment.comment"`

## `[files]`

How micro saves files.

### `create_folders`

Whether saving a file makes the folders it goes in when they're missing.

- Value: true or false
- Writes: `$HOME/.config/micro/settings.json` `mkparents`
