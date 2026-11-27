<!-- Made from the webapps.toml catalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

# webapps.toml reference

Every table and setting `webapps.toml` takes. A setting you leave out takes its default. A name a table doesn't take gets a warning. See [web apps](system-config.md#web-apps) for how it works.

## `[apps.<name>]`

Sites that get an app of their own in `~/Applications`.

- Names: the app's name, such as "Frigate", which names `Frigate.app`
- Each one needs every setting below but `icon`.

### `url`

The site, `http` or `https`.

- Value: text that isn't empty

### `icon`

A square `.png` or an `.icns` file, as a path inside dots, such as "icons/frigate.png". Left out, the app gets the plain app icon.

- Value: text that isn't empty
