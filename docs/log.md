# Log

The app writes what it does to the macOS system log, under the subsystem `com.jorisvandijk.malum`. Each entry has a category: `app` for the app itself, and the module's name for each module.

## malum log

`malum log` shows Malum's entries as they come in, one short line each, until you press ctrl+C:

```
09:00:00 app [info] running
09:00:02 samba [warn] couldn't mount data: the server didn't answer
```

`malum log --last 1h` shows the last hour and stops. The time is a number and `s`, `m`, `h` or `d`, such as `30m` or `2d`.

The rest of this page is for reading the system log yourself.

To watch the log live:

```sh
log stream --predicate 'subsystem == "com.jorisvandijk.malum"' --level info
```

To read the last hour:

```sh
log show --last 1h --predicate 'subsystem == "com.jorisvandijk.malum"' --info
```

Entries use the same tags as the terminal: `[info]` for things that changed, such as a module starting, and `[warn]` and `[error]` for anything the menu bar shows. Debug entries are off unless you ask for them with `--level debug` (or `--debug` for `log show`).

To see one module only, add its category, for example `and category == "system_config"` inside the predicate.

Paths and host names are private. The log shows each of them as `<private>`, so a line reads like this:

```
[info] loaded <private> <private>
```

The private values follow at the end of the line, and macOS hides them as well.
