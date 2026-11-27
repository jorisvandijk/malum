# Keyboard

The keyboard module gives you a hyper key, swaps keys around, and catches shortcuts for the other modules. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`:

```toml
[keyboard]
enabled = true
```

Everything else goes in `keyboard.toml`, at the top of your dots folder, next to `malum.toml`. Settings in a `[keyboard]` table besides `enabled` are a config error. Saving `keyboard.toml` puts it to work straight away.

The module needs Accessibility. Until it's granted, the module waits, and the [menu bar](menu-bar.md) offers to open the page in System Settings (see [permissions](permissions.md)).

## keyboard.toml

```toml
[hyper]
key = "caps_lock"

[remaps]
grave = "delete_forward"
non_us_backslash = "grave"

[shortcuts]
"hyper+f" = "com.apple.finder"
"hyper+return" = "net.kovidgoyal.kitty"
"ctrl+cmd+h" = "clipboard"
```

The [keyboard.toml reference](keyboard-settings.md) lists every table and the values each takes.

### [hyper] key

The key that holds ctrl, option, cmd and shift down together while you hold it. One of `caps_lock`, `left_option`, `right_option`, `right_command` or `f13` to `f20`. Leave it out for no hyper key.

Other apps see the hyper key as all four modifiers, so a shortcut such as hyper+k works in any app that lets you set one. Hyper+tab opens the app switcher, as cmd+tab does. With the [window manager](window-manager.md#adjusting-the-split) on, hyper+drag moves the borders between an app's windows, and that click doesn't reach the app.

### [remaps]

Each line makes the key on the left type as the key on the right, on every keyboard, while Malum runs. Remaps are undone when the module stops or Malum quits, and at the next start after a crash. The hyper key can't be remapped.

### [shortcuts]

Each line is a shortcut and what it does. A shortcut is its modifiers, `ctrl`, `option`, `cmd`, `shift`, or `hyper` for all four, then a key name, joined by `+` and in quotes: `"hyper+f"`, `"ctrl+shift+v"`. The modifiers can come in any order, and the same shortcut written twice is a config error. Every file in dots writes a shortcut this way.

The value is what the key does:

- Text with a dot is an app's bundle ID. The keyboard module opens no apps itself: it hands these keys to the [window manager](window-manager.md), which runs or raises the app. While the window manager is off, the key goes on to the front app as a normal shortcut, and the menu bar shows a warning on the module's line.
- Text without a dot is an action another module offers, named in that module's docs. An action no module offers is a config error at its line.

### Key names

`a` to `z`, `0` to `9`, `f1` to `f20`, `return`, `tab`, `space`, `delete`, `delete_forward`, `escape`, `left`, `right`, `up`, `down`, `home`, `end`, `page_up`, `page_down`, `minus`, `equal`, `open_bracket`, `close_bracket`, `backslash`, `semicolon`, `quote`, `grave`, `comma`, `period`, `slash`, `non_us_backslash`, `caps_lock`, `fn`, and `left_` or `right_` followed by `control`, `shift`, `option` or `command`.

## Staying on

Malum sets the hyper key and the remaps again when the Mac wakes from sleep, when you switch back to your login from another user, and when a keyboard is plugged in or reconnects. It keeps catching keys while it does, so a hyper key you hold down stays held. The log says which of these happened, then `set the key remaps again`. When Malum has to start catching keys again, such as after new settings, the log says `started the event tap again`.

The module's line in the [menu bar](menu-bar.md) warns, as `degraded`, about what keeps your keys from working:

- **Secure input:** while a password field or an app such as Terminal with Secure Keyboard Entry has secure input on, macOS hands no keys to Malum, so no shortcut works. The line names the app that holds it, and goes back to `running` once it lets go.
- **Modifier Keys:** System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys can change a key on one keyboard, such as caps lock to escape. When it changes your hyper key, the hyper key doesn't work on that keyboard. Set that key back to itself there.

Taking away Accessibility stops the module and undoes the hyper key and the remaps, so no key is left dead. It starts again once you grant it (see [permissions](permissions.md)). When you take it away and give it back within a few seconds, Malum notices that macOS switched off its key catching and starts it again. When the module can't catch keys or set the remaps while it runs, it shows as `failed` and undoes the hyper key and the remaps, so your hyper key types as itself until the next change to `keyboard.toml` or the next wake.

## Problems

Every problem in `keyboard.toml` is listed in the menu bar and the [log](log.md) with its line. A file with errors leaves the module on its last good settings.
