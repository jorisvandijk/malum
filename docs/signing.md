# Signing

macOS ties every permission it grants, such as Accessibility, to the app's code signature. Malum's releases are signed ad hoc, which gives every build a new signature, so each update would ask for every permission again. To keep one signature for good, Malum signs itself with a certificate of its own.

## The certificate

The first time the installed app starts, Malum makes a self-signed code signing certificate called **Malum code signing** and adds it to your login keychain. It lasts twenty years, never leaves your Mac, and is only used to sign Malum. Keychain Access lists it as not trusted, which is expected for a self-signed certificate and doesn't stop it from signing.

## Signing the app

At every start, the installed app at `~/Applications/Malum.app` checks that it's signed with that certificate. When it isn't, as on the first start after installing:

1. Malum copies the app to `~/Applications/Malum.app.staged`. The running app is never touched.
2. It signs the copy with the certificate, and checks the signature.
3. It swaps the copy into place in one step.
4. It starts again through its login agent, as the signed app.

When any step fails, the app that was there stays, and the reason shows in the menu bar.

### The keychain dialog

The first time Malum signs itself with a new certificate, macOS asks whether `codesign` may use the key in your login keychain. Type your Mac's login password and click **Always Allow**. From then on, Malum signs every update without asking.

- **Allow** works for this one signing only, so the dialog comes back with the next update.
- **Deny**, or leaving the dialog for 5 minutes, makes signing fail. The app stays as it was, the modules stay off, and the next start asks again.

No module starts until Malum is signed with its certificate. A copy of Malum that runs from anywhere else, such as a build folder, never signs itself, and keeps every module off. Its menu says so.

## A new Mac

The certificate lives in the login keychain, so a new Mac, or a new keychain, gets a new certificate. Malum makes it by itself, and every permission is granted once more.

To remove the certificate, quit Malum and run:

```sh
security delete-identity -c "Malum code signing" ~/Library/Keychains/login.keychain-db
```

The next start makes a new one and signs the app with it.
