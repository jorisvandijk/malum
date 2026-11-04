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

What gets installed is listed in `packages.toml`, at the top of your dots folder, next to `malum.toml`. Each way of installing has its own table: `[homebrew]` and `[app_store]`.

```toml
[homebrew]
bitwarden = "cask"
mas = "formula"
mole = "formula"
"olets/tap/zsh-abbr" = "formula"

[app_store]
amphetamine = 937984704
xcode = 497799835
```

In `[homebrew]`, each package is its name set to `"formula"` or `"cask"`. A package from a tap is written as `owner/tap/name`, in quotes. Homebrew adds the tap by itself, so taps aren't listed anywhere.

In `[app_store]`, each app is a name of your choosing set to its App Store ID, the number at the end of its App Store link (`apps.apple.com/app/xcode/id497799835`). The name only shows up in messages.

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

## App Store apps

App Store apps are installed after the Homebrew packages, with [mas](https://github.com/mas-cli/mas). List `mas = "formula"` under `[homebrew]`, and the same run installs it first. You have to be signed in to the App Store. Free apps are got for your account; a paid app has to have been bought with it already.

mas installs as root, so when an app is missing, `malum run` asks for your password once, in the terminal, and the rest of the run doesn't ask again. Outside a terminal it can't ask, and installs no App Store apps. What mas writes while it downloads shows up between Malum's own lines:

```
[info] every listed Homebrew formula is installed
[info] asking for your password to install App Store apps
[sudo] password for you:
[info] installing App Store app xcode (497799835)
[info] installed App Store app xcode
[info] system_config is done
```

An app that's already installed is left alone, and so is everything that isn't listed. When mas can't install an app, the error it wrote stays above `[error] couldn't install App Store app xcode: exited with 1`, and the rest still go ahead.

The messages also go to the macOS log, as the [log page](log.md) describes.
