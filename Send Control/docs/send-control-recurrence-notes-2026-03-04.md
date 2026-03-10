# Send Control Recurrence Notes (2026-03-04)

## Confirmed root causes

1. Permission denial stops tap startup by design
- Log signal:
  - `Start skipped (...): required permissions are missing.`
  - `Accessibility permission is not granted.`
- Result: menu appears, but protection never turns ON.

2. Ad-hoc signing causes trust instability across rebuild/reinstall
- Current binary is signed as `Signature=adhoc`, `TeamIdentifier=not set`.
- CDHash changes every rebuild.
- TCC trust can become invalid after replacing the app, requiring permission re-grant.

3. State mismatch (`desiredProtectionEnabled` vs `isEnabled`)
- Previous behavior could show OFF while internal desired state remained ON.
- Re-click behavior felt broken because toggle logic used desired state, not actual running state.

4. Duplicate app bundles in multiple install paths
- Same app existed in both `/Applications` and `~/Applications`.
- User could launch an older copy from Finder/Spotlight, causing inconsistent behavior and stale permissions.

## Fixes applied

1. Menu clarity and actionability
- First menu item is now clickable and explicit:
  - `Send Control: ON`
  - `Send Control: OFF`
- When permissions are missing, show actionable item:
  - `Grant Accessibility + Input Monitoring…`
  - or per-missing-permission variants.

2. Toggle behavior made deterministic
- Toggle decision now uses actual runtime state (`isEnabled || eventTapManager.isRunning`).
- If startup fails due permission/retry exhaustion, desired state is reset to OFF to avoid hidden ON state.

3. Diagnostics improved
- Launch logs include bundle identifier and runtime path:
  - `Bundle: com.example.IMEFix, path: /Applications/Send Control.app`

4. Canonical launch enforcement
- App now treats `/Applications/Send Control.app` as canonical.
- If launched from any other path and canonical exists, it immediately launches the canonical app and exits.
- This prevents accidental execution of stale copies.

## Operational checklist (fast)

1. Keep only one installed copy:
- `/Applications/Send Control.app`
- Remove any duplicates under `~/Applications` before testing.

2. After reinstall/update, verify permissions:
- System Settings > Privacy & Security > Accessibility
- System Settings > Privacy & Security > Input Monitoring
- Ensure `Send Control` is enabled.

3. Verify runtime quickly:
- `pkill -9 "Send Control"; /Applications/Send\ Control.app/Contents/MacOS/Send\ Control`
- Check logs include:
  - `CGEvent.tapCreate succeeded.`
  - `Event tap started successfully.`

4. Verify active app bundle ID when testing target:
- `osascript -e 'id of app (path to frontmost application as text)'`

## Next hardening recommendation

For development reliability, use stable non-adhoc signing (`Apple Development` with a fixed Team ID).  
This removes most permission resets after rebuild/reinstall.
