# System config

System config makes the Mac match dots. It's one module, `system_config`, with one switch, and it only does something when you run:

```sh
malum run
```

The app reads the module's settings like any other, but never acts on them. Nothing happens in the background.

## Switching it on

`malum run` works only when the module's table in `malum.toml` switches it on:

```toml
[system_config]
enabled = true
formulae = ["ripgrep", "bat"]
casks = ["kitty"]
```

When the table is missing, sets `enabled = false`, or has a problem, `malum run` changes nothing, says why, and exits with an error.

## Packages

`formulae` lists Homebrew formulae and `casks` lists Homebrew casks, by name. A package from a tap is written as `owner/tap/name`. Every setting is in the [config reference](config.md).

`malum run` asks Homebrew which packages are installed, and installs each listed one that's missing, one at a time:

```
[info] installing formula ripgrep
[info] installed formula ripgrep
[info] every listed cask is installed
[info] system_config is done
```

An install that fails is reported with the last line Homebrew wrote, and the rest still go ahead. The run then ends with `[error] system_config finished with errors` and exits with an error.

Homebrew itself has to be installed at `/opt/homebrew/bin/brew`. Packages that aren't listed are left alone, and removing a package from the list doesn't uninstall it.

A cask that runs an installer package needs your password, which `malum run` can't ask for yet, so its install fails.

The messages also go to the macOS log, as the [log page](log.md) describes.
