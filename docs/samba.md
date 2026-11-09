# Samba

The Samba module keeps shares from your Samba servers mounted under `/Volumes`, so they show in Finder and in the terminal. It runs in the app while it's switched on:

```toml
[samba]
enabled = true
```

## Servers

The servers go in `samba.toml` at the top of dots, one `[[server]]` each:

```toml
[[server]]
name = "nas"
host = "nas.local"
user = "joris"
shares = ["media", "backup"]
```

- `name` is what you call the server, such as `nas`. Each server needs its own.
- `host` is the server's host name or address.
- `user` is who to log in as.
- `shares` lists the shares to mount, at least one.

The servers can also go in a `[[samba.server]]` table in `malum.toml`, but not in both places. A mistake is reported with its line, and the module keeps the servers it had.

## Passwords

A server's password lives in your login keychain and nowhere else: not in dots and not in your shell's history. Store it with the server's name:

```sh
malum samba password nas
```

Malum asks for the password and hides what you type:

```
Password for joris@nas.local:
[info] saved the password for joris@nas.local in the login keychain
```

Running it again replaces the password. It's kept as a generic password called `com.jorisvandijk.malum.samba` with the account `joris@nas.local`, so **Keychain Access** shows it too.

## Mounting

When the module starts, on every network change and every five minutes, Malum looks at each share:

- A share whose server answers is mounted at `/Volumes/<share>`, without any dialog.
- A share whose server stopped answering is unmounted, so nothing hangs on it. It's mounted again once the server answers, such as when you're home again or your VPN is up.
- A share taken out of `samba.toml` is unmounted.

Stopping the module, or quitting Malum, leaves mounted shares as they are.

The first time Malum mounts a share, macOS asks whether Malum may use network volumes; choose **Allow**. When Malum first reads a password it didn't save itself, macOS may ask too; choose **Always Allow**.

A share that can't be mounted shows in the menu bar's menu, with what's wrong:

- **no password:** run `malum samba password <server>`.
- **the server refused the user or password:** run `malum samba password <server>` with the right one.
- **already taken:** something else is mounted at `/Volumes/<share>`, such as the same share mounted from Finder.

What Malum does is in its log, as the [log page](log.md) shows.
