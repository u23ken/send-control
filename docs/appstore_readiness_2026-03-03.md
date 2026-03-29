# Send Control App Store Readiness Check (2026-03-03)

## Verdict

NO-GO (close, but still blocked by identity/signing setup)

## Summary

- Functional build: PASS
- App Sandbox entitlement: PASS
- Privacy-sensitive verbose key logs in release binary: PASS (removed)
- Submission bundle identifier: FAIL
- Team signing setup: FAIL

## Verification Commands

Build command:

```bash
xcodebuild -project "/Users/ken/Documents/Trush/Codex/Customize Return Key/IMEFix.xcodeproj" -scheme IMEFix -configuration Release -derivedDataPath /tmp/IMEFixDerived build
```

Preflight command:

```bash
/Users/ken/Documents/Trush/Codex/Customize\ Return\ Key/tools/appstore_preflight.sh
```

Preflight result:

- `[PASS]` Release build succeeded.
- `[PASS]` App Sandbox entitlement present.
- `[FAIL]` Bundle identifier is still placeholder (`com.example.IMEFix`).
- `[FAIL]` Team identifier is not set (local ad-hoc signing).
- `[PASS]` No verbose key-event diagnostic strings detected.

## Current Artifact Snapshot

- App path: `/tmp/IMEFixDerived/Build/Products/Release/Send Control.app`
- Product name: `Send Control`
- Bundle ID: `com.example.IMEFix` (placeholder)
- Signing identity: local (`Sign to Run Locally`, ad-hoc)
- Team identifier: not set

Local identity inventory check:

```bash
security find-identity -v -p codesigning
```

Result in this environment:

- `0 valid identities found`

## What Was Improved in This Pass

1. Added App Sandbox entitlement file:
   - `IMEFix/SendControl.entitlements`
2. Wired entitlements into target build settings:
   - `CODE_SIGN_ENTITLEMENTS = IMEFix/SendControl.entitlements`
3. Added hardened runtime flag in target build settings.
4. Replaced ad-hoc print/NSLog with `os.Logger` wrapper:
   - `IMEFix/SendControlLog.swift`
5. Removed verbose per-keystroke diagnostics from release behavior.
6. Added deterministic preflight checker:
   - `tools/appstore_preflight.sh`

## Remaining Blockers Before App Store Submission

1. Replace placeholder bundle ID with production identifier.
2. Configure Apple Developer Team and App Store signing.
3. Produce and archive App Store distribution build from Xcode Organizer.

## Apple References

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Sandbox (macOS): https://developer.apple.com/documentation/security/app-sandbox
- Event tap/input monitoring discussion (Apple Developer Forums): https://developer.apple.com/forums/thread/789896
