# IMEFix Postmortem (2026-03-03)

## Outcome
- Final state is working.
- Verified logs show:
  - `CGEvent.tapCreate succeeded.`
  - `Event tap enabled.`
  - `Return detected: ... isTarget=true ... keyCode=36`
  - `Converted Return to Shift+Return (synthetic sequence, keyCode=36).`
  - `Swallowed original Return keyUp (keyCode=36).`

## Why it failed repeatedly
1. Multiple app copies existed and old binaries were sometimes launched.
- `/Applications`, `~/Applications`, `/tmp/IMEFixDerived`, and `DerivedData` all had `IMEFix.app`.
- Auto-selection logic originally treated temp/build outputs as "newest", causing unexpected fallback to stale behavior.

2. Permission preflight logic was too strict / misleading.
- Start flow depended on pre-checks instead of actual `CGEvent.tapCreate` result.
- This created false-negative loops where app appeared OFF even when direct tap creation could work.

3. Initial conversion method was not robust enough for Safari Web App context.
- Simply mutating event flags was not consistently effective.
- Stable behavior required: block original Return and inject explicit synthetic Shift+Return sequence.

4. Validation was sometimes done with wrong frontmost app.
- Some checks were run while Terminal was frontmost (`com.apple.Terminal`), not Safari WebApp.
- This led to contradictory observations.

## Fixes applied
- Restricted build-selection candidates to installed locations only:
  - `/Applications/IMEFix.app`
  - `~/Applications/IMEFix.app`
- Removed old app copies (all non-/Applications copies deleted).
- Changed startup policy to rely on actual tap creation attempt.
- Added Safari Web App matching support (`com.apple.Safari.WebApp.*`, WebKit WebContent fallback).
- Reworked key handling to:
  - block original Return keyDown,
  - emit synthetic `Shift down -> Return down/up -> Shift up`,
  - swallow original Return keyUp.

## Next-time no-waste checklist
1. Confirm running binary path first:
- `ps aux | rg '[I]MEFix.app/Contents/MacOS/IMEFix'`

2. Keep only one deployment copy:
- `/Applications/IMEFix.app`

3. Validate tap is alive before behavior tests:
- Look for `CGEvent.tapCreate succeeded` and `Event tap enabled`.

4. Validate while target app is actually frontmost:
- `osascript -e 'id of app (path to frontmost application as text)'`

5. On Return press, confirm all three lines:
- `Return detected ... isTarget=true`
- `Converted Return to Shift+Return (synthetic sequence...)`
- `Swallowed original Return keyUp ...`
