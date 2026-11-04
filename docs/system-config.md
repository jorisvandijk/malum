# System config

System config makes the Mac match dots. It's one module, `system_config`, with one switch, and it only does something when you run:

```sh
malum run
```

The app reads the switch like any other, but never acts on it. Nothing happens in the background.

## Switching it on

`malum run` works only when `malum.toml` switches the module on:

```toml
[system_config]
enabled = true
```

When the table is missing, sets `enabled = false`, or has a problem, `malum run` changes nothing, says why, and exits with an error.

## packages.toml

What gets installed is listed in `packages.toml`, at the top of your dots folder, next to `malum.toml`. Each way of installing has its own table. For now that's `[homebrew]`, where each package is its name set to `"formula"` or `"cask"`:

```toml
[homebrew]
bitwarden = "cask"
mole = "formula"
"olets/tap/zsh-abbr" = "formula"
```

A package from a tap is written as `owner/tap/name`, in quotes. Homebrew adds the tap by itself, so taps aren't listed anywhere.

Every problem in the file is reported with its line, and `malum run` then installs nothing:

```
[error] packages.toml line 3: homebrew.kitty should be "formula" or "cask"
[error] couldn't install packages: fix /Users/you/dots/packages.toml first
```

A table Malum doesn't know only gets a warning. Without a `packages.toml`, there's nothing to install.

## Installing

`malum run` asks Homebrew which packages are installed, and installs each listed one that's missing, one at a time, formulae first:

```
[info] installing Homebrew formula mole
[info] installed Homebrew formula mole
[info] every listed Homebrew cask is installed
[info] system_config is done
```

An install that fails is reported with the last line Homebrew wrote, and the rest still go ahead. The run then ends with `[error] system_config finished with errors` and exits with an error.

Homebrew itself has to be installed at `/opt/homebrew/bin/brew`. Packages that aren't listed are left alone, and taking a package out of the list doesn't uninstall it.

A cask that runs an installer package needs your password, which `malum run` can't ask for yet, so its install fails.

The messages also go to the macOS log, as the [log page](log.md) describes.
