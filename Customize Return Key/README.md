# Send Control GitHub Technical Preview

Send Control is a macOS menu bar utility that remaps Return and Shift+Return at the event-tap layer. This package is a technical preview / beta for testers who are comfortable with macOS security prompts, manual permission setup, and troubleshooting. It is not intended for general users.

## Status

- Technical preview / beta
- Release build from `release/send-control-1.1`
- Not notarized
- No Developer ID distribution
- Requires macOS 13 or later
- Requires Accessibility and Input Monitoring permissions

## What To Download

- `Send Control.app.zip`
- `SHA256SUMS.txt`

## Before You Launch

- Read [INSTALL.md](INSTALL.md) first.
- Read [PRIVACY.md](PRIVACY.md) before granting permissions.
- Read [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for current limitations.
- If `/Applications/Send Control.app` already exists on your Mac, move or remove it before testing this preview. This build can redirect to the installed copy.

## Opening An Unverified App

Because this build is not notarized, macOS may block the first launch.

1. Unzip `Send Control.app.zip`.
2. In Finder, Control-click `Send Control.app`, then choose `Open`.
3. If macOS still blocks it, open `System Settings > Privacy & Security`, find the message about Send Control, and choose `Open Anyway`.
4. Launch the app again and confirm `Open`.

## Required Permissions

Send Control needs both of the following macOS permissions:

- Accessibility
- Input Monitoring

Without both permissions, the event tap stays off and Return remapping will not work.

## Audience

This preview is for macOS-savvy testers who can:

- work through Gatekeeper warnings,
- inspect permissions in System Settings,
- compare behavior across apps,
- report exact reproduction steps.

If you want background on this package, see [RELEASE_NOTES_v1.1_beta.md](RELEASE_NOTES_v1.1_beta.md).
