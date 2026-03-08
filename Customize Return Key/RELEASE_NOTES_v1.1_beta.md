# Send Control v1.1 Beta Release Notes

Japanese RELEASE_NOTES: [RELEASE_NOTES_v1.1_beta.ja.md](RELEASE_NOTES_v1.1_beta.ja.md)

Date: 2026-03-08

## Summary

This package is the first GitHub technical preview pack for Send Control based on `release/send-control-1.1`. The goal of this pass is public-release packaging, not feature expansion. No app functionality was changed for this package.

## Included In This Pack

- Release build of `Send Control.app`
- `Send Control.app.zip`
- `SHA256SUMS.txt`
- `README.md`
- `INSTALL.md`
- `PRIVACY.md`
- `KNOWN_ISSUES.md`

## Current Build Position

- App version metadata: `1.1`
- Bundle identifier: `com.sendcontrol.app`
- Minimum macOS target: `13.0`
- Distribution status: technical preview / beta
- Notarization status: not notarized

## Expected Behavior

- Menu bar app
- Requires Accessibility and Input Monitoring permissions
- Remaps Return and Shift+Return using a CGEvent tap
- Stores only the local ON/OFF preference needed to restore protection state

## Not In Scope For This Pack

- Developer ID signing
- notarization
- installer package creation
- app feature changes

## Feedback Requested

- first-launch experience on a clean Mac,
- Gatekeeper and `Open Anyway` flow,
- Accessibility and Input Monitoring setup,
- behavior in target apps where Return remapping matters,
- regression reports with macOS version, target app name, and exact reproduction steps.
