# GitHub token

Malum's repository is private, so Malum needs a token to see its own releases. The token lives in `~/.config/malum/secrets/github/malum`, a file only you can read, and nowhere else: not in dots and not in your shell's history.

## Make the token

On GitHub, go to **Settings > Developer settings > Personal access tokens > Fine-grained tokens** and choose **Generate new token**:

- **Expiration:** No expiration.
- **Repository access:** Only select repositories, and pick `malum`.
- **Permissions:** Repository permissions > Contents: Read-only. Metadata: Read-only comes with it.

Copy the token GitHub shows. It's shown only once.

## Store it

```sh
malum token
```

Malum asks for the token and hides what you type, the way `sudo` hides a password:

```
GitHub token:
[info] saved the GitHub token in Malum's secrets
```

The token isn't an argument, so it never shows up in your history or in the list of running processes. Piping it in works too, for example straight from the clipboard:

```sh
pbpaste | malum token
```

Before it stores the token, Malum asks GitHub whether the token can read its repository. A token GitHub refuses isn't stored:

```
[error] couldn't save the GitHub token: GitHub refused the token, run malum token with a new one
```

Running `malum token` again replaces the stored token. Malum doesn't use the keychain, so nothing ever asks for your password to read the token, not even after an update. The secrets folder and its files can only be opened by you, though any app you run can read them, as it could read most of your home folder.

A token saved by Malum 0.12 or older is in the login keychain (`com.jorisvandijk.malum.github` or `.github-token`) and isn't used anymore: run `malum token` once more, then delete the old one in **Keychain Access**.

## Use

`malum run` reads the token once and sends it with every request to GitHub, including the lookups of the `[release.<name>]` packages. With a token, GitHub allows 5000 lookups an hour instead of 60. Releases of other public repositories keep working, since a token can read every public repository.

When GitHub refuses the stored token, for example because it was deleted on GitHub, the run says so:

```
[error] couldn't install GitHub release mpv: GitHub refused the token, run malum token with a new one
```

`malum status` says whether a token is stored, never the token itself:

```
[info] GitHub token: stored in Malum's secrets
```

## Remove it

```sh
malum token --remove
```

```
[info] removed the GitHub token from Malum's secrets
```
