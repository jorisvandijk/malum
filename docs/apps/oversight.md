<!-- Made from the oversight catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# oversight settings reference

Every setting `apps/oversight.toml` takes, by table. Each one has a name you can read, and Malum writes what oversight keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[startup]`

Whether OverSight opens at login.

### `at_login`

Whether OverSight opens when you log in.

- Value: true or false
- Writes: `com.objective-see.oversight` `startAtLogin`

## `[updates]`

Whether OverSight checks for new versions.

### `auto_check`

Whether OverSight checks for a new version when it starts.

- Value: true or false
- Writes: `com.objective-see.oversight` `noupdateMode`
