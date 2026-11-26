# Window manager

The window manager runs or raises apps from the shortcuts in `keyboard.toml`, hides the other apps when one comes to the front, and fills the screen with each app's windows. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`:

```toml
[window_manager]
enabled = true
```

The settings go either in the same table or in `window_manager.toml` (plain settings under `[settings]`, float rules as `[[float]]`), at the top of your dots folder, next to `malum.toml`. Use one or the other: settings in both places are a config error. Saving the file puts it to work straight away.

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

When an app comes to the front, in any way, every other app is hidden, so only one app is in view at a time. Apps without a Dock icon, such as menu bar apps, hide nothing, and neither does an app that floats as a whole.

## Filling the screen

Each app's windows fill the screen:

- One window takes the whole area.
- Two windows split it into a left and a right half.
- With more, the oldest window keeps the left half and the others stack on the right.

The split keys below change how much each window gets.

A window that's moved or resized snaps back to its place. A window that's dragged follows the pointer. Let go of it over another window's place and the two swap; let go anywhere else and it drops back into its own place. A window that can't grow to its place is centred in it, and one that can't shrink is pinned to its top left. An app that keeps resizing its own window is left where it settles.

### Adjusting the split

Four actions move the borders between an app's windows:

- `split_left` and `split_right` move the border between the left window and the others.
- `split_taller` and `split_shorter` make the focused window in the right column taller or shorter, taking room from or giving it to the windows above and below.

Each press moves a border by `split_step`, 5% of the area unless set otherwise. Neither column gets narrower than 20% of the area, and no window in the right column gets shorter than 20% of its height (less when so many windows share it that 20% each wouldn't fit). The left window always fills the height, so `split_taller` and `split_shorter` do nothing on it. With one window, nothing moves. Bind them in `keyboard.toml`:

```toml
[hyper]
left = "split_left"
right = "split_right"
up = "split_taller"
down = "split_shorter"
```

You can also drag the borders: hold the hyper key and drag anywhere in the app in front. Moving sideways moves the border between the left window and the others. A drag that starts in the right column also moves the border between two of its windows nearest the pointer up or down. No exact hit on a border is needed, the windows follow while you drag, and the same limits hold. The click itself never reaches the app, and a click without the hyper key works as usual. Hyper+drag needs the [keyboard](keyboard.md) module, which catches the clicks, and isn't a binding in `keyboard.toml`.

Each app keeps its own split, also after it quits and starts again. When the number of windows in the right column changes, their heights are shared out equally again. Malum forgets every split when it quits.

### Stacking the windows

The action `toggle_stack` stacks the windows of the app in front: each fills the whole area, on top of each other, with the focused one in front. The same key splits them again, with the split they had. `stack_next` and `stack_previous` bring the next or previous window to the front and give it the focus, oldest first and going round at either end, so with two windows either key switches between them. Bind them in `keyboard.toml`:

```toml
[hyper]
l = "toggle_stack"
comma = "stack_previous"
period = "stack_next"
```

The hyper key holds shift too, so hyper+comma is hyper+< and hyper+period is hyper+>.

The window in front follows the focus, so cmd+\` or the Window menu also changes it. Switch to another app and back, and the window that was in front is in front again. When it closes or is minimised, the one in front before it comes up. A new window joins the stack, in front. With one window left the app stays stacked, which looks the same as one window, until `toggle_stack` is pressed again. While an app is stacked, the split keys, hyper+drag and dropping a window on another do nothing. Floating windows aren't part of the stack. Each app is stacked on its own, and goes back to its split when it quits or Malum restarts.

Malum fills the screen with the menu bar. Other screens are left alone. When a display is plugged in, unplugged or rearranged, and when the Mac wakes, the windows are laid out again on the screen that has the menu bar then.

## Hiding and minimising

A hidden app or a minimised window would leave a gap, so the window manager swallows cmd+H (hide), cmd+M (minimise) and cmd+option+M (minimise all) while `block_hide_minimize` is on, which it is by default. The keys are caught by the [keyboard](keyboard.md) module, so they only work this way while it's on too. A shortcut in `keyboard.toml` on one of these keys is a config error, since the window manager has them.

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

### Floating a window by hand

The action `toggle_float` floats the focused window of the app in front: it's centred at a little over half the size of the area, and the app's other windows fill the space it left. The same key puts it back in the place it came from. Windows that float anyway, such as dialogs, are left as they are. Bind it in `keyboard.toml`:

```toml
[hyper]
t = "toggle_float"
```

A window floated this way stays floating until it's toggled back or closed, also when Malum lays the windows out again.

## Inspecting a window

The window manager's action `inspect_window` shows what Malum sees in a window, which helps when writing a float rule. Bind it to a key in `keyboard.toml`:

```toml
[hyper]
i = "inspect_window"
```

The key dims the screens a little and shows a crosshair. Click any window to see its app, bundle ID, title, role and subrole, frame (size and top left corner, in points from the top left of the screen with the menu bar), workspace (the keys that raise its app) and whether the window manager manages it, or why it floats. The click doesn't reach the window. Esc cancels. Copy puts the whole report on the clipboard, and esc closes it. Inspecting changes nothing.

## window_manager.toml

```toml
[settings]
frame = "visible"
block_hide_minimize = true
split_step = 5
```

- `frame`: `"visible"` fills the screen below the menu bar and outside the Dock, and `"full"` fills the whole screen.
- `block_hide_minimize`: swallows cmd+H, cmd+M and cmd+option+M, which would hide an app or minimise a window.
- `split_step`: how far the split keys move a border, in percent of the area, a whole number from 1 to 25. Anything else is a config error at its line.

Every key is optional, and the values above are the defaults. The [config reference](config.md) lists them all.
