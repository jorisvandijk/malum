<!-- Made from the modules' schemas by `swift run MalumDocs`. Edit the schemas, not this page. -->

# Config reference

Every setting `malum.toml` takes, by module. Each module's settings go in a table named after the module, such as `[system_config]`. A module is off until its table sets `enabled = true`. A setting that's left out takes its default, when it has one.

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
