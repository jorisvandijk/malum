# Window manager

The window manager runs or raises apps from the shortcuts in `keyboard.toml`, hides the other apps when one comes to the front, and fills the screen with each app's windows. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`:

```toml
[window_manager]
enabled = true
```

The settings go either in the same table or in `window_manager.toml`, at the top of your dots folder, next to `malum.toml`. Use one or the other: settings in both places are a config error. Saving the file puts it to work straight away.

The module needs Accessibility. Until it's granted, the module waits, and the [menu bar](menu-bar.md) offers to open the page in System Settings (see [permissions](permissions.md)).

## Run or raise

A shortcut in `keyboard.toml` whose value is a bundle ID opens that app:

```toml
[hyper]
f = "com.apple.finder"
return = "net.kovidgoyal.kitty"
```

Pressing it starts the app when it isn't running. When it is, Malum shows it if it's hidden, brings it to the front, opens a new window when it has none, and brings back a minimised window when every window is minimised. Pressing it again while the app is already in front does nothing.

The [keyboard page](keyboard.md) explains the shortcuts.

## Hiding the others

When an app comes to the front, in any way, every other app is hidden, so only one app is in view at a time. Apps without a Dock icon, such as menu bar apps, hide nothing, and neither does an app that floats as a whole. `hide_others = false` switches this off.

## Filling the screen

Each app's windows fill the screen:

- One window takes the whole area.
- Two windows split it into a left and a right half.
- With more, the oldest window keeps the left half and the others stack on the right.

A window that's moved or resized snaps back to its place. A window that's dragged follows the pointer and drops back into place when you let go. A window that can't grow to its place is centred in it, and one that can't shrink is pinned to its top left. An app that keeps resizing its own window is left where it settles.

Malum fills the screen with the menu bar. Other screens are left alone.

## Floating windows

A floating window is left where it is. Dialogs, panels, sheets, modal windows, windows of a fixed size and native fullscreen windows always float. Float rules add more:

```toml
# Every window of this app floats.
[[float]]
app = "com.apple.systempreferences"

# Only windows whose title matches the pattern float.
[[float]]
app = "org.mozilla.librewolf"
title = "^Picture-in-Picture$"
```

`app` is a bundle ID, and `title` is a regular expression. A title that isn't a valid expression is a config error at its line, and only that rule is left out.

## window_manager.toml

```toml
frame = "visible"
hide_others = true
block_hide_minimize = true
```

- `frame`: `"visible"` fills the screen below the menu bar and outside the Dock, and `"full"` fills the whole screen.
- `hide_others`: hides every other app when one comes to the front.
- `block_hide_minimize`: swallows cmd+H, cmd+M and cmd+option+M, which would hide an app or minimise a window.

Every key is optional, and the values above are the defaults. The [config reference](config.md) lists them all.
