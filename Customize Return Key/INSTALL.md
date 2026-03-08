# Install Send Control Technical Preview

## Scope

These instructions are for the GitHub technical preview package dated 2026-03-08. This build is not notarized.

## 1. Download And Verify

1. Download `Send Control.app.zip` and `SHA256SUMS.txt`.
2. Verify the ZIP checksum:

```bash
shasum -a 256 "Send Control.app.zip"
```

3. Compare the output with the `Send Control.app.zip` entry in `SHA256SUMS.txt`.

## 2. Prepare Your Mac

1. If `/Applications/Send Control.app` already exists, move it out of the way before testing this preview.
2. Unzip `Send Control.app.zip`.
3. Place `Send Control.app` somewhere in your home folder, for example `~/Applications/` or `~/Desktop/Send Control Preview/`.

## 3. Open The App

1. In Finder, Control-click `Send Control.app`.
2. Choose `Open`.
3. If macOS shows a warning because the app is from an unidentified developer, confirm `Open`.
4. If Finder still refuses to open it, go to `System Settings > Privacy & Security` and use `Open Anyway`, then try again.

Optional advanced fallback for testers:

```bash
xattr -dr com.apple.quarantine "Send Control.app"
```

Use that command only if you understand the security tradeoff.

## 4. Grant Required Permissions

Send Control requires both permissions below:

1. `System Settings > Privacy & Security > Accessibility`
2. `System Settings > Privacy & Security > Input Monitoring`

After granting permission, relaunch the app if protection does not turn on by itself.

## 5. Confirm It Is Running

1. Look for the Send Control menu bar icon.
2. Open the menu bar item and confirm protection is ON.
3. Test Return and Shift+Return in the target app you care about.

## 6. Remove The Preview

1. Quit Send Control from the menu bar.
2. Delete `Send Control.app`.
3. Remove Accessibility and Input Monitoring permission entries if you no longer want them enabled. See [PRIVACY.md](PRIVACY.md).
