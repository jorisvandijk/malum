# Clipboard history

The clipboard history keeps what you copy, and shows it in the same popup as the [launcher](launcher.md), to put back and paste. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`. The settings go either in the same table or in `clipboard.toml`, at the top of your dots folder:

```toml
[clipboard]
enabled = true
size = 300
paste = true
```

- `size`: how many copies the history keeps, at least 1. The oldest go first. Making it smaller drops the oldest straight away.
- `paste`: picking an entry pastes it into the app below, besides putting it on the clipboard. With `false` it's only put on the clipboard.

The module needs Accessibility, to paste. Its action is `clipboard`, which you bind to a key in `keyboard.toml`:

```toml
[hyper]
h = "clipboard"
```

## What it keeps

Every copy of text (with its formatting, so a paste into Notes keeps it), images and files. For files it keeps only their paths, never the files themselves. Copying something already in the history moves it to the top. Images over 20 MB aren't kept.

Copies that password managers and other apps mark as concealed or transient (the nspasteboard.org convention) are never kept; the [log](log.md) says when one was skipped.

The history lives in `history/` in Malum's state folder, readable only by you, so it survives a restart.

If System Settings > Privacy & Security > Paste from Other Apps denies Malum the clipboard, nothing is recorded, and the module's line in the [menu bar](menu-bar.md) says so as `degraded`. Set it to allow.

## The popup

The popup lists the history, newest first, each with how long ago you copied it: `now`, `5m`, `3h`, `2d`. Typing searches it the same way as the launcher, the newest first among equally good matches.

- **Return** or a click puts the entry on the clipboard, makes it the newest, and pastes it into the app below. Files paste as files in Finder and as their paths elsewhere.
- **cmd+backspace**, or the (x) on a selected or hovered row, deletes an entry.
- **Clear all**, at the top right, deletes every entry after a second click.
- **Tab** switches to the launcher's apps and back, keeping what you typed.
- The other keys work as in the [launcher](launcher.md#the-popup).
