# Permissions

macOS asks before an app watches the keyboard, controls other apps or reads other apps' data, and remembers the answer per app. Malum keeps its answers across updates because it's always [signed](signing.md) with its own certificate.

## Modules

Each module needs its own permissions. A module that's switched on but missing one doesn't start. Its line in the [menu bar](menu-bar.md) says `needs` with the permissions it's missing, and an item under it for each one opens the page in System Settings where you grant it. For Accessibility, Input Monitoring and Screen Recording, picking the item also adds Malum to the list on that page, so you only have to switch it on. For the others, add `~/Applications/Malum.app` with the **+** button.

Malum checks every 2 seconds while a module runs or waits. A module that waits starts as soon as its permissions are granted, without a restart. A running module that loses a permission, such as when you switch Malum off in System Settings, stops, undoes what it changed, and waits for it again. The log says when a module stops, waits and starts.

macOS has no way to tell whether an app has App Management, Automation, Local Network or Network Volumes. A module that needs one of those starts anyway, and says so itself when macOS refuses.

## The terminal

A command run in a terminal counts as the terminal app, not as Malum. So when `malum` touches another app's data or a network volume, macOS asks about your terminal, and keeps asking. Giving the terminal Full Disk Access covers all of it.

To check, run:

```sh
malum permissions
```

When the terminal has Full Disk Access, it says so:

```
[info] kitty has Full Disk Access
```

When it doesn't, it says what to do and opens the Full Disk Access page in System Settings:

```
[warn] kitty doesn't have Full Disk Access, so macOS keeps asking kitty about what malum does in it; turn it on in System Settings > Privacy & Security > Full Disk Access, then quit and reopen kitty
[info] opened System Settings at Full Disk Access
```

Switch the terminal on in that list, then quit and reopen the terminal, since macOS only applies the change to a fresh start. When `malum permissions` doesn't run in a terminal, such as from a script with no terminal attached, it says there's no terminal to check.
