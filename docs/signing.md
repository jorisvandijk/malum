# Signing

macOS ties every permission it grants, such as Accessibility, to the app's code signature. Malum's releases are signed ad hoc, which gives every build a new signature, so each update would ask for every permission again. To keep one signature for good, Malum signs itself with a certificate of its own.

## The certificate

The first time the installed app starts, Malum makes a self-signed code signing certificate called **Malum code signing**. It and its key go in `~/.config/malum/signing.pem`, a file only you can read. It lasts twenty years, never leaves your Mac, and is only used to sign Malum and its web apps.

Malum doesn't use the keychain for it, so signing never asks for your password, not after an update and not for a new web app. Next to it, `~/.config/malum/signing.req` holds the rule every signature carries: "signed with this certificate". That rule is what macOS checks a permission against, so it stays the same from one update to the next.

## Signing the app

At every start, the installed app at `~/Applications/Malum.app` checks that it's signed with that certificate. When it isn't, as on the first start after installing:

1. Malum copies the app to `~/Applications/Malum.app.staged`. The running app is never touched.
2. It signs the copy with the key file, using the `rcodesign` that comes inside Malum.app, and checks the signature with macOS's own `codesign`.
3. It swaps the copy into place in one step.
4. It starts again through its login agent, as the signed app.

When any step fails, the app that was there stays, and the reason shows in the menu bar.

No module starts until Malum is signed with its certificate. A copy of Malum that runs from anywhere else, such as a build folder, never signs itself, and keeps every module off. Its menu says so.

## A new Mac

The key file lives in `~/.config/malum`, so a new Mac gets a new certificate unless you copy `signing.pem` and `signing.req` over. Malum makes it by itself, and every permission is granted once more: run `malum permissions`.

To start over with a new certificate, quit Malum and run:

```sh
command rm ~/.config/malum/signing.pem ~/.config/malum/signing.req
```

The next start makes a new one and signs the app with it.

## Before 0.13

Malum 0.12 and older kept the certificate in the login keychain. It isn't used anymore; you can delete **Malum code signing** in **Keychain Access**.

`rcodesign` is [apple-codesign](https://github.com/indygreg/apple-platform-rs), under the Mozilla Public License 2.0, which comes with it as `Contents/Resources/rcodesign-COPYING`.
