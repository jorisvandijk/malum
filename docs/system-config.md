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

A table or setting Malum doesn't know only gets a warning. Without a `packages.toml`, there's nothing to install.

## Installing

`malum run` asks Homebrew which packages are installed, and installs each listed one that's missing, one at a time, formulae first:

```
[info] installing Homebrew formula mole
[info] installed Homebrew formula mole
[info] every listed Homebrew cask is installed
[info] system_config is done
```

An install that fails is reported with the last line Homebrew wrote, and the rest of the run still goes ahead: the other packages, the app config files and the macOS settings.

Every warning and error in a run gets a number as it happens, and the run ends with all of them again, so none get lost in the output. It then exits with an error when any of them is one:

```
[info] installing Homebrew cask lulu
[error] #1 couldn't install Homebrew cask lulu: Download failed on Cask 'lulu'
[info] wrote ~/.gitconfig from apps/git.toml
[warn] #2 apps/kitty.toml line 4: unknown setting settings.fontsize
[error] 2 issues in this run:
[error] #1 couldn't install Homebrew cask lulu: Download failed on Cask 'lulu'
[warn] #2 apps/kitty.toml line 4: unknown setting settings.fontsize
```

Homebrew itself has to be installed at `/opt/homebrew/bin/brew`. Taking a package out of the list uninstalls it, as [Removing](#removing) describes.

A cask that runs an installer package needs your password, which `malum run` can't ask for, so its install fails.

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

Each `[release.<name>]` table installs an app or a program from the latest release of a GitHub repository, after the App Store apps. `repo` is the repository, as `owner/name`. `asset` names the file to download, with `*` matching any text; leave it out when the release has only one file, or only one with `mac`, `darwin` or `apple` in its name. Checksums and notes such as `.sha256` and `.txt` files don't count. Only public repositories work, since the [GitHub token](github-token.md) reads Malum's own repository only.

Zip files and tarballs are unpacked, along with one more archive inside them. An app (`mpv.app`) goes to `/Applications`, and a program goes to `~/.local/bin`, under the table's name, so the name can't be empty, start with a dot or hold `/`. A file that isn't an archive is the program itself. Installers (`.dmg`, `.pkg`) can't be installed. Both folders are settings of system config in `malum.toml`:

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

An app or program that's already where a listed release goes is replaced by the release, and Malum manages it from then on:

```
[info] installing GitHub release mpv v0.40.0 (mpv-v0.40.0-macos-15-arm.zip)
[info] /Applications/mpv.app was already there and was replaced, Malum manages it now
[info] installed GitHub release mpv v0.40.0 at /Applications/mpv.app
```

The one exception is a place another listed release is installed: two releases never replace each other.

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

- `[theme]` and `[settings]`: any of [kitty's options](https://sw.kovidgoyal.net/kitty/conf/), as `option = value`, each written as an `option value` line. `true` and `false` are written as `yes` and `no`. The theme is written first, so a setting wins over it. A list writes the option once for each item, for options kitty takes more than once, such as `symbol_map`.
- `[keybindings]`: keyboard shortcuts, as `"keys" = "action"`. Each becomes a `map keys action` line.

### LibreWolf

`apps/librewolf.toml` writes LibreWolf's settings and look into its profile, `~/Library/Application Support/LibreWolf/Profiles/default`, and sets its policies for every user of the Mac. LibreWolf reads all of it when it starts: quit and reopen it after a run. Install LibreWolf itself with the `librewolf` cask.

```toml
[settings]
"sidebar.verticalTabs" = true
"toolkit.legacyUserProfileCustomizations.stylesheets" = true

[user_chrome]
text = '''
#alltabs-button { display: none !important; }
'''

[policies]
EnterprisePoliciesEnabled = true
DisableTelemetry = true

[policies.ExtensionSettings."uBlock0@raymondhill.net"]
installation_mode = "force_installed"
install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"

[[policies.SearchEngines.Add]]
Name = "Startpage"
URLTemplate = "https://www.startpage.com/search?q={searchTerms}"
```

- `[settings]`: preferences, as you'd find them in `about:config`, as `"name" = value`. Names have dots, so quote them. Each is written to the profile's `user.js` as `user_pref("name", value);`, which LibreWolf applies every time it starts. A value is text, a number, or `true` or `false`.
- `[user_chrome]`: `text` is written to the profile's `chrome/userChrome.css` as it is, to change LibreWolf's own interface. LibreWolf only reads it when `toolkit.legacyUserProfileCustomizations.stylesheets` is `true` in `[settings]`.
- `[policies]`: [Mozilla's enterprise policies](https://mozilla.github.io/policy-templates/), by their own names: add-ons, search engines, bookmarks, and settings for add-ons such as uBlock Origin's filters. They're set in the system-wide preferences `/Library/Preferences/net.librewolf.librewolf`, like the [app preferences](#app-preferences) but for every user, so a run that changes them asks for your password. Set `EnterprisePoliciesEnabled = true`, or LibreWolf ignores the rest. `defaults read /Library/Preferences/net.librewolf.librewolf` shows what's set, and `about:policies` in LibreWolf shows what it took.

The profile is always called `default`. When `~/Library/Application Support/LibreWolf/profiles.ini` is missing, Malum writes one that makes LibreWolf start with it, and when the profile has no `compatibility.ini`, Malum writes the one LibreWolf leaves in a profile it has used, so LibreWolf takes the profile on its first start instead of making a new one. Both are for LibreWolf in `/Applications`, where the cask puts it. After that the files are LibreWolf's: Malum doesn't change, record or remove them. `user.js` and `userChrome.css` are only written when their table has something in it.

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

### newsboat

`apps/newsboat.toml` writes newsboat's config, `~/.config/newsboat/config`, and its feeds to `~/.config/newsboat/urls`. What you've read is kept in newsboat's cache, which Malum leaves alone. Install newsboat itself with the `newsboat` formula in `packages.toml`.

```toml
[settings]
auto-reload = true
reload-time = 60
browser = "open %u"

[keybindings]
j = "down"
J = "next-feed articlelist"

[ignore_articles]
"*" = ["title =~ \"sponsored\"", "author = \"bot\""]

[feeds]
"Hacker News" = "https://news.ycombinator.com/rss"
Lobsters = { url = "https://lobste.rs/rss", tags = ["tech"] }
```

- `[settings]`: any of [newsboat's options](https://newsboat.org/releases/2.42/docs/newsboat.html#_configuration_commands), as `option = value`. Text is written in double quotes, `true` and `false` as `yes` and `no`.
- `[keybindings]`: key bindings, as `key = "operation"`, each written as `bind-key key operation`. Put a dialog after the operation to bind it in that dialog only, as `J` does above.
- `[ignore_articles]`: articles to hide, as `feed = "filter"`, or a list of filters. Each filter becomes an `ignore-article feed "filter"` line. The feed is its address, or `"*"` for every feed, and the filter is in [newsboat's filter language](https://newsboat.org/releases/2.42/docs/newsboat.html#_filter_language).
- `[feeds]`: the feeds, as `title = "address"`. The title is shown in newsboat's feed list instead of the feed's own. Use `{ url = "...", tags = [...] }` to give a feed tags. The feeds are written in alphabetical order of title, and `urls` is only written when there's at least one.

### ssh

`apps/ssh.toml` writes ssh's per-user config, `~/.ssh/config`, with one table inside `[hosts]` for each `Host` section. Each setting goes by the name ssh gives it, and `true` and `false` are written as `yes` and `no`. Your keys stay out of dots: only the settings that point at them go here.

```toml
[hosts."github.com"]
IdentityFile = "~/.ssh/id_ed25519"
AddKeysToAgent = true
UseKeychain = true
```

writes

```
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
  UseKeychain yes
```

ssh takes the first value it finds, so hosts with a plain name come first and patterns, such as `"*"`, last; each group is in alphabetical order, and so are the settings inside a host.

### VSCodium

`apps/vscodium.toml` writes VSCodium's settings to `~/Library/Application Support/VSCodium/User/settings.json` and its startup options to `~/.vscode-oss/argv.json`, and installs the extensions it lists. Install VSCodium itself with the `vscodium` cask in `packages.toml`, which also gives Malum the `codium` command it installs extensions with.

```toml
[extensions]
ids = ["dracula-theme.theme-dracula", "tamasfe.even-better-toml"]

[settings]
"workbench.colorTheme" = "Dracula Theme"
"editor.fontLigatures" = true

[argv]
enable-crash-reporter = false
```

- `[extensions]`: `ids` lists extensions as `publisher.name`, their name on [Open VSX](https://open-vsx.org). Malum installs them after the app config files, and works with them the way it does with packages: one that's already installed is taken over, and one you take out of the list is uninstalled. Extensions you installed yourself and never listed are left alone. When `apps/vscodium.toml` has an error, extensions are neither installed nor uninstalled.
- `[settings]`: [user settings](https://code.visualstudio.com/docs/configure/settings), as `"name" = value`. Names have dots, so quote them. Changing a setting in VSCodium changes `settings.json`, so the next run overwrites it with a warning: change settings here instead.
- `[argv]`: startup options, as `option = value`. `argv.json` is only written when the table has something in it.

```
[info] installing VSCodium extension tamasfe.even-better-toml
[info] installed VSCodium extension tamasfe.even-better-toml
```

### zsh

`apps/zsh.toml` writes zsh's startup files: `~/.zshenv`, `~/.zprofile`, `~/.zshrc` and zsh-abbr's `~/.config/zsh-abbr/user-abbreviations`. New shells pick up changes; open ones keep what they started with. Malum doesn't change your login shell, and installs no plugins: list them in `packages.toml` and load them in `[zshrc]`.

```toml
[environment]
EDITOR = "micro"
NOTES = "$HOME/notes"

[profile]
text = '''
eval "$(/opt/homebrew/bin/brew shellenv)"
'''

[aliases]
".." = "cd .."
gs = "git status"

[zshrc]
text = '''
setopt share_history hist_ignore_space
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
PROMPT='%~ %# '
'''

[abbreviations]
symlink = "ln -s"

[global_abbreviations]
pc = "| pbcopy"
```

- `[environment]`: variables, as `NAME = "value"`, each written to `~/.zshenv` as `export NAME="value"`, so every zsh gets them, scripts included. The value is in double quotes, so `$HOME` and other variables expand.
- `[profile]`: `text` is written to `~/.zprofile` as it is, for login shells.
- `[aliases]`: aliases, as `name = "command"`, each written at the top of `~/.zshrc` as `alias name='command'`. The command is in single quotes, so a variable in it expands when the alias runs.
- `[zshrc]`: `text` is written to `~/.zshrc` as it is, after the aliases: options, history, plugins, the prompt, functions.
- `[abbreviations]` and `[global_abbreviations]`: [zsh-abbr](https://zsh-abbr.olets.dev) abbreviations, which expand as you type, as `name = "text"`. Global ones expand anywhere on the line, not only as the command. Adding one with `abbr add` changes the file, so the next run overwrites it with a warning: add them here instead.

`~/.zshrc` is always written; the other files only when their table has something in it. Use a TOML literal string, in `'''`, for `text`, so backslashes and quotes stay as they are.

## App preferences

Some apps keep their settings as macOS preferences rather than in a file. Their file in `apps/` has one table, `[preferences]`, with each preference by the name the app stores it under, as `"Name" = value`. `defaults read <domain>` lists an app's current preferences. Malum sets them after the app config files, the way `defaults write` would:

```
[info] set Hide Dock Icon in com.if.Amphetamine from apps/amphetamine.toml
[info] amphetamine reads its preferences when it starts: quit and reopen it to use the new ones
[info] every app preference is up to date
```

A value is text, a number, `true` or `false`, or a list or table of them; a table becomes a dictionary. Malum owns each preference it sets: one you change in the app is set back on the next run. When you take a preference out of the file, or remove the file, the next run removes it, so the app falls back to its own default. Preferences that aren't in the file are left alone. Malum keeps the names of the preferences it set in `installed.json`.

| App | File | Domain | Install with |
| --- | --- | --- | --- |
| Amphetamine | `apps/amphetamine.toml` | `com.if.Amphetamine` | the App Store app 937984704 |
| Command X | `apps/command-x.toml` | `com.sindresorhus.Command-X` | the App Store app 6448461551 |
| Cursorcerer | `apps/cursorcerer.toml` | `com.doomlaser.cursorcerer` | the `cursorcerer` cask |
| OverSight | `apps/oversight.toml` | `com.objective-see.oversight` | the `oversight` cask |

```toml
# apps/amphetamine.toml
[preferences]
"Hide Dock Icon" = true
"Default Duration" = 0
```

Command X stores a shortcut as text holding JSON: `KeyboardShortcuts_cut = '{"carbonKeyCode":7,"carbonModifiers":256}'` is ⌘X.

## macOS settings

macOS's own settings are set from `macos.toml`, at the top of your dots folder, last in the run. Each domain has its own table inside `[preferences]`, with each setting by the name macOS stores it under, the way `defaults write` takes them. `defaults read <domain>` lists a domain's current settings; quote a domain with dots in it.

```toml
[preferences.NSGlobalDomain]
AppleInterfaceStyle = "Dark"
KeyRepeat = 2
InitialKeyRepeat = 30

[preferences."com.apple.finder"]
ShowPathbar = true
FXPreferredViewStyle = "Nlsv"

[preferences."com.apple.dock"]
autohide = true

[current_host."com.apple.controlcenter"]
Timer = 8
```

`[current_host]` holds the few settings macOS keeps for this Mac only, the ones `defaults -currentHost` reads, in the same shape.

A value is text, a number, `true` or `false`, or a list or table of them. Malum owns each setting it sets, as with [app preferences](#app-preferences): one you change in System Settings is set back on the next run, and one you take out of the file is removed, so macOS goes back to its own default. Settings the file doesn't name are left alone. When `macos.toml` is missing or has an error, no setting is touched. Malum keeps the names of the settings it set in `installed.json`, under `macos`.

After a change, Malum tells running apps about it, and restarts Finder, the Dock, the menu bar or Control Center when their settings changed:

```
[info] set autohide in com.apple.dock from macos.toml
[info] restarted Dock to use the new settings
[info] some macOS settings, such as key repeat, take full effect after you log out and back in
```

The last line shows when a setting changed that nothing can be restarted for.

### Hosts and Touch ID for sudo

Two more tables in `macos.toml` change files that only root can change. They use the run's one password prompt, and only ask when a file has to change.

```toml
[hosts]
"ha.home" = "10.0.0.110"

[sudo]
touch_id = true
```

`[hosts]` holds the names this Mac looks up itself instead of asking DNS, each with its address. With this table Malum owns `/etc/hosts`: it writes macOS's own lines followed by one line for each name, then makes macOS read the file again. An empty `[hosts]` leaves only macOS's own lines. Taking the table out puts back the file macOS ships with.

`touch_id = true` in `[sudo]` lets `sudo` in the terminal take Touch ID instead of the password, through `/etc/pam.d/sudo_local`, which macOS keeps across updates. `false`, or taking it out, removes that file when Malum wrote it.

These work like app config files: a file that was already there, or that was changed outside Malum, is overwritten, and the old one is kept next to it with `.backup` added, with a warning that gives the `diff` command to see what changed. A file Malum wrote that was changed by hand stays when you take its table out, and Malum lets it go. Malum keeps the files it wrote in `installed.json`, under `system_files`.

```
[info] asking for your password to change /etc/hosts or Touch ID for sudo
[info] wrote /etc/pam.d/sudo_local from macos.toml
```

### Power settings

`[power]` in `macos.toml` sets the power settings, with one table for each power source: `battery` and `charger`. Each setting goes by the name `pmset` gives it, and `pmset -g custom` lists them with their values.

```toml
[power.battery]
lessbright = 0
```

Setting them needs root, so they use the run's one password prompt, and only ask when a setting has to change. Malum owns each setting it sets: one you change outside Malum is set back on the next run. One you take out of the file goes back to what it was before Malum first set it, unless you changed it outside Malum: then it stays, and Malum lets it go. A table for a power source this Mac doesn't have, such as `battery` on a desktop Mac, is skipped with a warning. Malum keeps the settings it set and what they were before in `installed.json`, under `power`.

```
[info] asking for your password to change power settings
[info] set lessbright on battery power to 0 from macos.toml (it was 1)
```

### Removing Apple apps

`remove` in `[apple_apps]` lists the Apple apps to remove from `/Applications`, by name without `.app`.

```toml
[apple_apps]
remove = ["GarageBand", "iMovie", "Keynote", "Numbers", "Pages"]
```

Malum removes each one it finds on every run, so an app that the App Store or a macOS update puts back is removed again. Only an app whose bundle ID starts with `com.apple.` is removed; any other app by that name stays, with an error. Removing needs root and uses the run's one password prompt. Taking a name out doesn't bring the app back: get it from the App Store.

```
[info] asking for your password to remove Apple apps
[info] removed /Applications/GarageBand.app, it's in [apple_apps] remove in macos.toml
```

### Default apps

`[default_apps]` in `macos.toml` picks the apps that open links and files, by bundle ID. `browser` opens web links (`http`, `https`) and web pages (`public.html`, `public.xhtml`). `video` opens video files (`public.mpeg-4`, `com.apple.quicktime-movie`, `public.avi`, `org.matroska.mkv`, `public.3gpp`, `public.mpeg`, `com.microsoft.windows-media-wmv`).

```toml
[default_apps]
browser = "net.librewolf.librewolf"
video = "io.mpv"
```

`osascript -e 'id of app "LibreWolf"'` gives an app's bundle ID. The app has to be installed, so put it in `packages.toml` too. A default app changed by hand is set back on the next run. A file type that no app on this Mac knows yet is skipped until one does. Taking a key out leaves the default app as it is. Setting them needs no password, but macOS asks you to confirm each change in a dialog of its own: one for the browser, which also covers `https` and `public.html`, and one for each video file type that changes. When you keep the old app, Malum stops asking for that key in this run, and the run ends with an error.

```
[info] macOS asks you to confirm net.librewolf.librewolf for http links, in a dialog of its own
[info] made net.librewolf.librewolf the default app for http links from macos.toml
```

## Status

`malum status` shows what Malum manages and what doesn't match dots right now. It changes nothing and never asks for your password. It works whether `system_config` is on or off.

For each kind of thing Malum manages it prints one count, followed by a warning for each thing that's off: a listed package or release that isn't installed, one Malum manages that isn't listed anymore, a file Malum wrote that is missing or was changed outside Malum, and a power setting that holds something else than Malum set. Each warning says what the next `malum run` does about it.

```
[info] managed Homebrew formulae: 41
[warn] Homebrew formula fd isn't installed, malum run installs it
[info] managed App Store apps: 3
[info] managed app config files: 14
[warn] /Users/you/.config/kitty/kitty.conf was changed outside Malum, malum run overwrites it and keeps a .backup
[info] managed macOS settings: 23
[info] managed power settings: 2
[warn] lessbright on battery power is 0, Malum set it to 1, malum run sets it back
```

When nothing is off, the last line says so:

```
[info] everything Malum manages matches dots
```

App preferences and macOS settings are only counted. VSCodium extensions are checked against what Malum installed, not against `apps/vscodium.toml`. A problem in `packages.toml` is reported, and `malum status` then exits with an error.
