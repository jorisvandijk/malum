# Malum

Malum fixes Apple's OS for me. It makes macOS work the way I want, and what I want may change over time.

The name is Latin: *malum* means both "bad" and "apple".

Malum is one app. It runs in the menu bar and can also be used as a command in the terminal. Everything it does is a module, and each module is switched on or off in its config.

It runs on macOS Tahoe, on Apple silicon.

## Install

1. Download `Malum-macos-arm64.zip` from the latest [release](https://github.com/jorisvandijk/malum/releases), while signed in to GitHub, since the repository is private.
2. Check the download against its `.sha256` file:

   ```sh
   cd ~/Downloads
   shasum -a 256 -c Malum-macos-arm64.zip.sha256
   ```

3. Unzip it and move the app to `~/Applications`:

   ```sh
   ditto -x -k Malum-macos-arm64.zip ~/Applications
   ```

4. Remove the quarantine flag. Malum isn't notarized by Apple, so without this step Gatekeeper refuses to open it:

   ```sh
   xattr -dr com.apple.quarantine ~/Applications/Malum.app
   ```

5. Check that it runs:

   ```sh
   ~/Applications/Malum.app/Contents/MacOS/Malum --version
   ```

   The first start links `~/.local/bin/malum` to the app, so from then on `malum` works as a command, as long as `~/.local/bin` is on your `PATH`. If something else is already at that path, Malum leaves it alone and `malum init` reports it.

## Set up

Malum reads its config from your dots checkout. Tell it where that is:

```sh
malum init <path to dots>
```

This saves the path in `~/.config/malum/config`, the only file Malum keeps outside dots, and points `~/.local/bin/malum` at the app again, for example after the app has moved. Run it again whenever dots moves.

After that, store a GitHub token so Malum can see its own releases, as the [GitHub token page](docs/github-token.md) explains:

```sh
malum token
```

## Config

Malum's settings live in `malum.toml`, at the top of your dots folder. Each module has its own table in it, named after the module, such as `[window_manager]`. Every setting is listed in the [config reference](docs/config.md).

When the app starts, it reads `malum.toml`. While it runs, saving the file is enough: the app sees the change and reads the file again. Saving without changing anything does nothing. `malum reload` makes the app read the file again even when nothing changed.

Every problem in the file is reported at once, each with the line it's on:

```
[error] malum.toml line 3: window_manager.gap should be a whole number
[warn] window_manager keeps its last good settings
```

A problem in one module's table affects only that module. It keeps the settings it had before, and the other modules take their new settings as normal. When the file isn't valid TOML at all, every module keeps its settings until the file is fixed.

## Use

Malum runs as the menu bar app when you open `Malum.app`, from Finder or with `open`, and as a command when you run `malum` in a terminal. Both are the same program.

In a terminal, the word in each message's tag is coloured: `info` green, `warn` yellow and `error` red. Set `NO_COLOR` to any value to turn that off. Output sent to a file or a pipe, and the log, are never coloured.

Only one app runs at a time. Opening `Malum.app` again while it runs does nothing, and the second copy quits straight away.

To make the running app reload, run:

```sh
malum reload
```

If the app isn't running, `malum reload` says so and exits with an error.

The app writes what it does to the macOS log. The [log page](docs/log.md) shows how to read it.

The app and the command keep their shared state in `~/Library/Application Support/com.jorisvandijk.malum`.

The [menu bar page](docs/menu-bar.md) explains Malum's icon and its menu.

A module that's missing a permission waits until you grant it, and `malum permissions` checks that your terminal has Full Disk Access. The [permissions page](docs/permissions.md) explains both.

`malum run` makes the Mac match dots: for now, it installs the Homebrew formulae and casks listed in `packages.toml` in dots. `malum status` shows what Malum manages and what doesn't match dots. The [system config page](docs/system-config.md) explains how.

At the end of every run, Malum updates itself to its latest release, and `malum rollback` puts the version it replaced back. The [updates page](docs/updates.md) explains how.

When something keeps crashing Malum, it turns on safe mode by itself, with every module off. `malum safe` turns it on by hand, and `malum disable <module>` keeps one module off. The [safe mode page](docs/safe-mode.md) has the details.

## Start at login

When the app starts from `~/Applications/Malum.app`, it makes sure `~/Library/LaunchAgents/com.jorisvandijk.malum.plist` is there, and from the next login on, macOS starts Malum when you log in. The first time, macOS shows a "Background Items Added" notification. The file is the same for every version of Malum, so updates don't bring the notification back. A copy of Malum running from anywhere else, such as a build folder, leaves the file alone.

When Malum crashes, macOS starts it again after 10 seconds. Quitting it from the menu bar keeps it closed until the next login. This works for the copy that macOS started at login; a copy opened from Finder isn't restarted.

To stop Malum from starting at login, switch it off under **System Settings > General > Login Items & Extensions**.
