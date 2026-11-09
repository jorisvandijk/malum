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
hyper_key = "caps_lock"

[remap]
grave = "delete_forward"
non_us_backslash = "grave"

[hyper]
f = "com.apple.finder"
return = "net.kovidgoyal.kitty"
```

### hyper_key

The key that holds ctrl, option, cmd and shift down together while you hold it. One of `caps_lock`, `left_option`, `right_option`, `right_command` or `f13` to `f20`. Leave it out for no hyper key.

Other apps see the hyper key as all four modifiers, so a shortcut such as hyper+k works in any app that lets you set one. Hyper+tab opens the app switcher, as cmd+tab does.

### [remap]

Each line makes the key on the left type as the key on the right, on every keyboard, while Malum runs. Remaps are undone when the module stops or Malum quits, and at the next start after a crash. The hyper key can't be remapped.

### Shortcut tables

One table per set of modifiers, each a flat list of keys and what they do. Name a table after its modifiers joined in the order `ctrl`, `option`, `cmd`, `shift`, such as `[ctrl]`, `[ctrl_shift]`, `[option_cmd]` or `[cmd_shift]`. All four together is `[hyper]`. A table in another order is a config error that names the right spelling.

The value is what the key does:

- Text with a dot is an app's bundle ID. The keyboard module opens no apps itself: it hands these keys to the module that handles apps. Until there is one, the key goes on to the front app as a normal shortcut, and the menu bar shows a warning on the module's line.
- Text without a dot is an action another module offers, named in that module's docs. An action no module offers is a config error at its line.

### Key names

`a` to `z`, `0` to `9`, `f1` to `f20`, `return`, `tab`, `space`, `delete`, `delete_forward`, `escape`, `left`, `right`, `up`, `down`, `home`, `end`, `page_up`, `page_down`, `minus`, `equal`, `open_bracket`, `close_bracket`, `backslash`, `semicolon`, `quote`, `grave`, `comma`, `period`, `slash`, `non_us_backslash`, `caps_lock`, `fn`, and `left_` or `right_` followed by `control`, `shift`, `option` or `command`.

## Problems

Every problem in `keyboard.toml` is listed in the menu bar and the [log](log.md) with its line. A file with errors leaves the module on its last good settings.
