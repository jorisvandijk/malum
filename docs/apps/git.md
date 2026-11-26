<!-- Made from the git catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

# git settings reference

Every setting `apps/git.toml` takes, by table. Each one has a name you can read, and Malum writes what git keeps it as, which it lists under "Writes". A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name. A name a table doesn't take gets a warning.

## `[user]`

Who your commits are by.

### `name`

Your name.

- Value: text that isn't empty
- Writes: `$HOME/.config/git/config` `user.name`

### `email`

Your email address.

- Value: text that isn't empty
- Writes: `$HOME/.config/git/config` `user.email`

## `[branches]`

The branches of new repositories.

### `default`

The name of the first branch of a new repository, such as "main".

- Value: text that isn't empty
- Writes: `$HOME/.config/git/config` `init.defaultBranch`

## `[hooks]`

The hooks every repository runs.

### `folder`

The folder git takes hooks from, instead of each repository's own.

- Value: a path, starting with $HOME/ in your home folder or / outside it
- Writes: `$HOME/.config/git/config` `core.hooksPath`

## `[push]`

What git push does.

### `auto_set_upstream`

Whether pushing a new branch makes it on the remote and tracks it, without --set-upstream.

- Value: true or false
- Writes: `$HOME/.config/git/config` `push.autoSetupRemote`

## `[github]`

How git reaches GitHub.

### `use_ssh`

Whether git reaches GitHub over ssh, even for an https:// address.

- Value: true or false
- Writes: `$HOME/.config/git/config` `url.git@github.com:.insteadOf`
