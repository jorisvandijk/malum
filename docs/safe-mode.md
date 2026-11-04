# Safe mode

In safe mode, only Malum's menu bar icon runs. Every module stays off, whatever `malum.toml` says, until you leave safe mode from the menu.

## When it turns on

- **After a crash loop.** Malum writes down each start. When it starts 3 times within 2 minutes, it takes that for a crash at every start, and turns safe mode on by itself. Quitting Malum from the menu bar forgets the starts, so quitting and opening it again a few times doesn't count.
- **When you ask.** Run:

  ```sh
  malum safe
  ```

Safe mode stays on across restarts until you leave it.

## Keeping one module off

To keep one module off without editing `malum.toml`, run:

```sh
malum disable <module>
```

The module stays off until you enable it again from the menu bar, even when `malum.toml` switches it on.

Both commands work whether the app runs or not. They save the change in Malum's state folder, `~/Library/Application Support/com.jorisvandijk.malum`, so dots isn't touched. When the app runs, they ask it to reload, and the change takes effect straight away. Otherwise it takes effect at the next start.

## Getting out

Open the menu bar icon:

- **Leave safe mode** turns safe mode off, and the modules start as `malum.toml` says.
- **Enable \<module\>** lets a disabled module run again.

## Cleanup at every start

Some modules change things that outlive the app, such as a key remap. Every time Malum starts, before any module runs, each module first undoes whatever an earlier run may have left behind, whether the module is switched on or not. A Malum that crashed or was killed leaves nothing broken after its next start, safe mode included.
