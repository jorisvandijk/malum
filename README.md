# Malum

Malum fixes Apple's OS for me. It makes macOS work the way I want, and what I want may change over time.

The name is Latin: *malum* means both "bad" and "apple".

Malum is one app. It runs in the menu bar and can also be used as a command in the terminal. Everything it does is a module, and each module is switched on or off in its config.

It runs on macOS Tahoe, on Apple silicon.

## Install

1. Download `Malum-macos-arm64.zip` from the latest [release](https://github.com/jorisvandijk/malum/releases).
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
