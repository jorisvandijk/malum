<!-- Made from the ssh catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# ssh settings reference

Every setting `apps/ssh.toml` takes, by table. Each one has a name you can read, and Malum writes what ssh keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[agent]`

What ssh does with the agent that holds your keys.

### `add_keys`

Whether ssh gives a key it uses to the agent, so you unlock it once.

- Value: true or false
- Writes: `$HOME/.ssh/config` `*.AddKeysToAgent`

### `use_keychain`

Whether ssh keeps the passphrases of keys in the macOS keychain.

- Value: true or false
- Writes: `$HOME/.ssh/config` `*.UseKeychain`

## `[keys.<name>]`

Your keys, and the hosts each one is for.

- Names: a name for the key, such as github
- Each one needs every setting below.

### `file`

The key's private file, such as "$HOME/.ssh/id_ed25519".

- Value: a path, starting with $HOME/ in your home folder or / outside it
- Writes: `$HOME/.ssh/config` `<hosts>.IdentityFile`

### `hosts`

The hosts ssh uses the key for.

- Value: a list of at least one host name or pattern, such as "github.com" or "*.example.com"
