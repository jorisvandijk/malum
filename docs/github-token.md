# GitHub token

Malum's repository is private, so Malum needs a token to see its own releases. The token lives in your login keychain and nowhere else: not in dots, not in a file and not in your shell's history.

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
[info] saved the GitHub token in the login keychain
```

The token isn't an argument, so it never shows up in your history or in the list of running processes. Piping it in works too, for example straight from the clipboard:

```sh
pbpaste | malum token
```

Before it stores the token, Malum asks GitHub whether the token can read its repository. A token GitHub refuses isn't stored:

```
[error] couldn't save the GitHub token: GitHub refused the token, run malum token with a new one
```

Running `malum token` again replaces the stored token. It's kept as a generic password called `com.jorisvandijk.malum.github` in the login keychain, so **Keychain Access** shows it too. When a new copy of Malum reads it for the first time, macOS may ask whether to allow that; choose **Always Allow**.

## Use

`malum run` reads the token once and sends it with every request to GitHub, including the lookups of the `[release.<name>]` packages. With a token, GitHub allows 5000 lookups an hour instead of 60. Releases of other public repositories keep working, since a token can read every public repository.

When GitHub refuses the stored token, for example because it was deleted on GitHub, the run says so:

```
[error] couldn't install GitHub release mpv: GitHub refused the token, run malum token with a new one
```

`malum status` says whether a token is stored, never the token itself:

```
[info] GitHub token: stored in the login keychain
```

## Remove it

```sh
malum token --remove
```

```
[info] removed the GitHub token from the login keychain
```
