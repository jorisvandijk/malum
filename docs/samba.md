# Samba

The Samba module mounts shares from your Samba servers under `/Volumes`.

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
