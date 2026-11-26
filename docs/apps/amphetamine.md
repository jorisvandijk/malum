<!-- Made from the amphetamine catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# amphetamine settings reference

Every setting `apps/amphetamine.toml` takes, by table. Each one has a name you can read, and Malum writes what amphetamine keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

Malum always writes these, which have no setting:

- `com.if.Amphetamine` `Icon Style`: `0`
- `com.if.Amphetamine` `Default Duration`: `0`

## `[appearance]`

Where Amphetamine shows. Amphetamine's settings, Appearance.

### `show_dock_icon`

Whether Amphetamine has an icon in the Dock as well as in the menu bar.

- Value: true or false
- Writes: `com.if.Amphetamine` `Hide Dock Icon`

## `[sessions]`

What a session that keeps the Mac awake allows. Amphetamine's settings, Sessions.

### `allow_display_sleep`

Whether the display may sleep while the Mac stays awake.

- Value: true or false
- Writes: `com.if.Amphetamine` `Allow Display Sleep`

### `allow_sleep_when_closed`

Whether a MacBook may sleep when its lid is closed.

- Value: true or false
- Writes: `com.if.Amphetamine` `Allow Closed-Display Sleep`

### `allow_screen_saver`

Whether the screen saver may start.

- Value: true or false
- Writes: `com.if.Amphetamine` `Allow Screen Saver`

### `move_pointer`

Whether Amphetamine moves the pointer now and then, for apps that watch it.

- Value: true or false
- Writes: `com.if.Amphetamine` `Enable Mouse Movement`

## `[statistics]`

Amphetamine's count of its sessions.

### `enabled`

Whether Amphetamine keeps statistics of its sessions.

- Value: true or false
- Writes: `com.if.Amphetamine` `Enable Statistics`
