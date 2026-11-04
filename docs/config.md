<!-- Made from the modules' schemas by `swift run MalumDocs`. Edit the schemas, not this page. -->

# Config reference

Every setting `malum.toml` takes, by module. Each module's settings go in a table named after the module, such as `[window_manager]`. A module is off until its table sets `enabled = true`. A setting that's left out takes its default, when it has one.

## `system_config`

Makes the Mac match dots when you run `malum run`. Nothing happens in the background: the app only reads these settings, and `malum run` does the work.

### `system_config.casks`

Homebrew casks to install, by name, such as `"kitty"`. A cask from a tap is written as `"owner/tap/name"`. `malum run` installs each one that isn't installed yet.

- Value: a list of text
- Default: `[]`

### `system_config.enabled`

Switches the module on. The module stays off until this is set to true.

- Value: true or false
- Default: `false`

### `system_config.formulae`

Homebrew formulae to install, by name, such as `"ripgrep"`. A formula from a tap is written as `"owner/tap/name"`. `malum run` installs each one that isn't installed yet.

- Value: a list of text
- Default: `[]`
