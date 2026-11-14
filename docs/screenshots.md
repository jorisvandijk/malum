# Screenshots

The screenshots module freezes the screen the mouse is on, lets you crop it and draw on it, and saves it. It runs in the app while it's switched on.

## Switching it on

The switch lives in `malum.toml`. The settings go either in the same table or in `screenshots.toml`, at the top of your dots folder:

```toml
[screenshots]
enabled = true
folder = "~/Documents"
colors = ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#007aff", "#ffffff", "#000000"]
```

- `folder`: where screenshots are saved. `~` is your home folder. Malum creates it when it's missing.
- `colors`: the quick colors in the toolbar, 1 to 7 as `"#rrggbb"`. The first is the color you start with. Left out, they're red, orange, yellow, green, blue, white and black.

The module needs Screen Recording. Its action is `screenshot`, which you bind to a key in `keyboard.toml`:

```toml
[hyper]
s = "screenshot"
```

`malum screenshot` in a terminal does the same while the app runs.

## Taking a shot

The key freezes the screen: what you see is what was there when you pressed it. A colored border round the screen shows it's the frozen shot, not the live screen, and the toolbar sits at the top.

You start with the select tool. Drag a rectangle to keep only that part: it moves to the middle of the screen. Press Return without selecting anything to keep the whole screen. Undo takes a selection back, so you can pick again; what you drew stays where it was.

## Drawing

The toolbar groups its buttons in panels, each with its key underneath:

| Key | Does |
| --- | --- |
| `S` | select a part to keep |
| `L` | draw a line |
| `A` | draw an arrow |
| `R` | draw a rectangle |
| `T` | type text where you click |
| `1` to `7` | pick a quick color |
| `P` | open macOS's color picker for any other color |
| `[` and `]` | thinner or thicker lines, smaller or bigger text |
| `=` and `-` | zoom in and out |
| `0` | back to real size |
| `B` | move the toolbar to the bottom and back, when it's in the way |
| cmd+Z, shift+cmd+Z | undo, redo |
| Return | save |
| Escape | close without saving |

While you type text, keys go to the text. A click, Escape or Return ends it.

Scrolling moves the shot around, and scrolling with cmd held or pinching zooms. Zoom only changes what you see: saved files are always at real size.

## What's saved

Return saves the part you kept as `malum-ss-<date>_<time>.png` in the folder, such as `malum-ss-2026-11-09_20-14-09.png`. When you drew something, it also saves `malum-ss-<date>_<time>-annotated.png` next to it. The clipboard gets the annotated shot, or the plain one when you drew nothing. A name that's taken gets `-2`, `-3` and so on.

Escape saves nothing.
