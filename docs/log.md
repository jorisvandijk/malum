# Log

The app writes what it does to the macOS system log, under the subsystem `com.jorisvandijk.malum`. Each entry has a category: `app` for the app itself, and the module's name for each module.

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
