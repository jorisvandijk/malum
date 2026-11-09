# Launcher

The launcher opens a popup in the middle of the screen with every app, to search and start one. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`. The launcher has no other settings:

```toml
[launcher]
enabled = true
```

It needs no permission. Its action is `launcher`, which you bind to a key in `keyboard.toml`:

```toml
[hyper]
space = "launcher"
```

The [keyboard page](keyboard.md) explains the shortcuts.

## The popup

The popup lists every app in `/Applications` and `~/Applications` (with folders inside them, such as `Utilities`, Nix's `Nix Apps` and Safari's web apps), Apple's own apps and Finder, from A to Z. An app installed or removed shows up in the list within a second.

Typing searches the list: the letters have to come in the name in that order, but not next to each other. Matches at the start of the name or of a word come first, then the apps you start most often from the launcher. Case and accents don't count.

- **Up** and **down**, or **ctrl+p** and **ctrl+n**, move the selection. **Page up** and **page down** move a page.
- **Return** or a click starts the app.
- **Tab** switches to the popup's next list, keeping what you typed.
- **Escape**, the launcher's key again, or a click anywhere else closes it.

Malum never becomes the active app for the popup, so nothing changes until you pick an app.

## Starting an app

When the [window manager](window-manager.md) runs, the app you pick is started or brought into view exactly as its shortcut would, and the other apps are hidden. Without it, the app is opened the way Finder opens it.

Malum keeps how often you started each app from the launcher in `launches.json` in its state folder, to put those first.
