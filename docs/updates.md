# Updates

Malum updates itself at the end of every `malum run`, after system config. The menu bar app never updates itself, and nothing happens in the background.

## How an update goes

`malum run` asks GitHub for Malum's latest release. When it's the version that runs, it says so:

```
[info] Malum 0.2.0 is up to date
```

When it's newer, Malum downloads `Malum-macos-arm64.zip` and its `.sha256` into its state folder, and checks it before anything changes:

1. The download matches its checksum.
2. The app in it has Malum's bundle ID.
3. It signs the app with its own certificate, the one the [signing page](signing.md) describes, and checks the signature. A copy that isn't signed with it is never installed, because macOS would drop every permission.
4. The signed app says it's the version of the release, when asked with `--version`.

Only then does it swap the new app in for `~/Applications/Malum.app`, in one step, and restart the menu bar app through its login agent:

```
[info] updating Malum 0.2.0 to 0.3.0
[info] updated Malum to 0.3.0; malum rollback puts 0.2.0 back
```

The first update may bring up the keychain dialog the signing page explains.

When any check fails, the app that was there stays as it is, the download is removed, and the run ends with an error:

```
[error] couldn't update Malum: Malum-macos-arm64.zip doesn't match its checksum
```

The command that runs keeps going on the version it started with, so the rest of the run is done by the old version. The next `malum run` runs the new one.

## Older releases

Malum never installs a release that's older than the version that runs, unless you ask for it:

```
[warn] the latest release, 0.1.0, is older than Malum 0.2.0; run malum run --force to install it
```

`malum run --force` installs it, with the same checks.

## Copies that don't update

Only the app in `~/Applications/Malum.app` updates itself. A copy that runs from anywhere else, such as a build folder, and a build that isn't a release, leave it alone:

```
[info] not updating: Malum isn't running from /Users/you/Applications/Malum.app
[info] not updating: this is a dev build of Malum, not a release
```

## Rolling back

Each update keeps the version it replaced, in `previous/Malum.app` in Malum's state folder, replacing the one kept before. To put it back:

```sh
malum rollback
```

```
[info] rolled back Malum to 0.2.0; malum rollback puts 0.3.0 back
```

Rolling back swaps the two, so running it again goes forward to the newer one. It restarts the menu bar app the same way an update does. The kept version is checked to be signed with Malum's certificate first. Without one, it says so and changes nothing:

```
[error] couldn't roll back Malum: no previous version is kept
```

The next `malum run` updates a rolled-back Malum again.
