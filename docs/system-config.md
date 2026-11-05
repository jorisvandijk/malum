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

What gets installed is listed in `packages.toml`, at the top of your dots folder, next to `malum.toml`. Each way of installing has its own table: `[homebrew]`, `[app_store]` and `[release.<name>]`.

```toml
[homebrew]
bitwarden = "cask"
mas = "formula"
mole = "formula"
"olets/tap/zsh-abbr" = "formula"

[app_store]
amphetamine = 937984704
xcode = 497799835

[release.mpv]
repo = "mpv-player/mpv"
asset = "mpv-*-macos-15-arm.zip"

[release.pagefind]
repo = "CloudCannon/pagefind"
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

Homebrew itself has to be installed at `/opt/homebrew/bin/brew`. Taking a package out of the list uninstalls it, as [Removing](#removing) describes.

A cask that runs an installer package needs your password, which `malum run` can't ask for yet, so its install fails.

## App Store apps

App Store apps are installed after the Homebrew packages, with [mas](https://github.com/mas-cli/mas). List `mas = "formula"` under `[homebrew]`, and the same run installs it first. You have to be signed in to the App Store. Free apps are got for your account; a paid app has to have been bought with it already.

mas installs and uninstalls as root, so when an app is missing or has to go, `malum run` asks for your password once, in the terminal, and the rest of the run doesn't ask again. Outside a terminal it can't ask, and installs or uninstalls no App Store apps. What mas writes while it downloads shows up between Malum's own lines:

```
[info] every listed Homebrew formula is installed
[info] asking for your password to install App Store apps
[sudo] password for you:
[info] installing App Store app xcode (497799835)
[info] installed App Store app xcode
[info] system_config is done
```

An app that's already installed is left alone. When mas can't install an app, the error it wrote stays above `[error] couldn't install App Store app xcode: exited with 1`, and the rest still go ahead.

## GitHub releases

Each `[release.<name>]` table installs an app or a program from the latest release of a GitHub repository, after the App Store apps. `repo` is the repository, as `owner/name`. `asset` names the file to download, with `*` matching any text; leave it out when the release has only one file, or only one with `mac`, `darwin` or `apple` in its name. Checksums and notes such as `.sha256` and `.txt` files don't count. Only public repositories work for now.

Zip files and tarballs are unpacked, along with one more archive inside them. An app (`mpv.app`) goes to `/Applications`, and a program goes to `~/.local/bin`, under the table's name. A file that isn't an archive is the program itself. Installers (`.dmg`, `.pkg`) can't be installed. Both folders are settings of system config in `malum.toml`:

```toml
[system_config]
enabled = true
release_apps = "/Applications"
release_programs = "~/.local/bin"
```

Malum remembers what it installed. The next run installs a newer release over it, and leaves one that's up to date alone:

```
[info] installing GitHub release mpv v0.40.0 (mpv-v0.40.0-macos-15-arm.zip)
[info] installed GitHub release mpv v0.40.0 at /Applications/mpv.app
[info] every listed GitHub release is up to date
```

Malum never replaces an app or program it didn't install itself. Remove it by hand first, and the next run installs the release in its place:

```
[error] couldn't install GitHub release mpv: /Applications/mpv.app is already there, and Malum didn't install it
```

Taking a release out of the list removes it, as [Removing](#removing) describes.

## Removing

Malum keeps a record of the packages, apps and releases it manages, in `installed.json` in its folder in `~/Library/Application Support/`. It manages what it installed, and also everything listed that a run finds already installed, which it says once:

```
[info] Homebrew formula mole was already installed, Malum manages it now
```

When you take something it manages out of `packages.toml`, the next run uninstalls it: Homebrew packages with `brew uninstall`, App Store apps with `mas uninstall`, and releases by removing the app or program Malum put in place.

```
[info] uninstalling Homebrew cask kitty
[info] uninstalled Homebrew cask kitty
[info] asking for your password to uninstall App Store apps
[sudo] password for you:
[info] uninstalling App Store app xcode (497799835)
[info] uninstalled App Store app xcode
[info] removed GitHub release mpv from /Applications/mpv.app
```

Anything that was never listed is left alone, even when it's installed. Something you already uninstalled by hand is only taken out of the record. A formula that other packages still need stays installed, and Malum stops managing it:

```
[warn] Homebrew formula libyaml is still needed by other packages, so it stays and Malum no longer manages it
```

An uninstall that fails is reported, stays in the record and is tried again on the next run. Without a `packages.toml`, or with an error in it, nothing is uninstalled.

## App config files

Each app whose config Malum writes has its own file in the `apps` folder at the top of your dots folder, named after the app: `apps/git.toml`. `malum run` writes the app's own config files from it, after the packages. A file in `apps/` for an app Malum doesn't know only gets a warning. Without an `apps` folder, nothing is written or removed.

```
[info] wrote /Users/you/.config/git/config from apps/git.toml
[info] every app config file is up to date
```

Every file Malum writes starts with a comment that says where it comes from. Malum owns these files: change the TOML in dots, not the file. When a file was changed outside Malum since the last run, or was already there before Malum first wrote it, the next run writes over it and keeps the old one next to it, with `.backup` added to its name, replacing an older backup. The warning gives the command that shows what changed:

```
[warn] /Users/you/.config/git/config was changed outside Malum, so it was overwritten from apps/git.toml, see what changed with: diff /Users/you/.config/git/config.backup /Users/you/.config/git/config
```

A link in the place of a file is replaced by the file. A file that's already right is only recorded. Malum keeps a fingerprint of each file it wrote in `installed.json`, to spot changes.

When an app's file has an error, its config files are left as they are, and the run ends with an error. When an app stops asking for a file, because you took a list out of its TOML or removed the TOML, the next run removes the file, unless it was changed outside Malum: then it stays, and Malum no longer manages it.

### git

`apps/git.toml` writes git's per-user config, `~/.config/git/config`. Settings in `~/.gitconfig` still apply on top of it, so keep that file empty or remove it.

```toml
[settings.user]
name = "Joris"
email = "joris@example.com"

[settings.init]
defaultBranch = "main"

[settings."url.git@github.com:"]
insteadOf = "https://github.com/"

[ignore]
patterns = [".DS_Store", "*.swp"]

[attributes]
lines = ["*.pdf diff=pdf"]
```

- `[settings.<section>]`: one table for each section of git's config, with its keys spelled the way git spells them. A dot in the section's name makes a subsection: `"url.git@github.com:"` becomes `[url "git@github.com:"]`. Values are text, whole numbers, `true` or `false`, or a list of them, which writes the key once for each item.
- `[ignore]`: `patterns` is written to `~/.config/git/ignore`, one per line, and git ignores them in every repository.
- `[attributes]`: `lines` is written to `~/.config/git/attributes`, which applies to every repository.

`ignore` and `attributes` are only written when their list has something in it.

### kitty

`apps/kitty.toml` writes kitty's config, `~/.config/kitty/kitty.conf`. kitty reads its config when it starts; press ctrl+cmd+, in a running kitty to load the new one.

```toml
[theme]
foreground = "#f8f8f2"
background = "#282a36"

[settings]
font_family = "CaskaydiaCove Nerd Font Mono"
font_size = 14
scrollback_lines = 100000
enable_audio_bell = false

[keybindings]
"cmd+b" = "launch --location=vsplit"
```

- `[theme]` and `[settings]`: any of [kitty's options](https://sw.kovidgoyal.net/kitty/conf/), as `option = value`, each written as an `option value` line. `true` and `false` are written as `yes` and `no`. The theme is written first, so a setting wins over it.
- `[keybindings]`: keyboard shortcuts, as `"keys" = "action"`. Each becomes a `map keys action` line.

### micro

`apps/micro.toml` writes micro's options to `~/.config/micro/settings.json`, its key bindings to `bindings.json`, and each colour scheme to its own file in `colorschemes/`, all in `~/.config/micro/`. JSON has no comments, so `settings.json` and `bindings.json` don't start with the line that says where they come from.

```toml
[settings]
colorscheme = "dracula"
softwrap = true

[bindings]
"Alt-/" = "lua:comment.comment"

[colorschemes.dracula]
default = "#F8F8F2,#282A36"
comment = "italic #6272A4"
```

- `[settings]`: any of [micro's options](https://github.com/zyedidia/micro/blob/master/runtime/help/options.md), as `option = value`. Setting an option from inside micro with `set` changes `settings.json`, so the next run overwrites it with a warning: set options here instead.
- `[bindings]`: [key bindings](https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md), as `"key" = "action"`. `bindings.json` is only written when the table has something in it.
- `[colorschemes.<name>]`: a colour scheme, with `group = "colours"` for each highlight group. Each becomes a `color-link group "colours"` line in `colorschemes/<name>.micro`. Pick the scheme with the `colorscheme` setting.

The messages also go to the macOS log, as the [log page](log.md) describes.
