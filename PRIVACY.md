# Send Control Privacy Notes

Japanese PRIVACY: [PRIVACY.ja.md](PRIVACY.ja.md)

## What Send Control Monitors

Send Control installs a macOS session event tap after you grant permission. It monitors:

- global `keyDown` and `keyUp` keyboard events,
- only Return (`keyCode 36`) and keypad Enter (`keyCode 76`) as remap candidates,
- modifier flags needed to preserve Command, Control, and Option behavior and to distinguish Shift+Return,
- the frontmost app bundle identifier needed to decide whether to remap the key event.

## What Send Control Does Not Store

Send Control does not save:

- typed text,
- message contents,
- a keystroke history,
- clipboard contents,
- screenshots,
- a list of the apps you used,
- network analytics or cloud data.

Send Control persists two local preferences: whether protection was last left ON or OFF, and the user-configured app exclusion list. macOS may also keep its own permission records and unified logs. Send Control does not add its own telemetry or sync service.

## What Send Control Sends

Send Control contains no network sending logic. It does not connect to any server.

## How To Remove Permissions

To revoke Send Control permissions:

1. Quit the app.
2. Open `System Settings > Privacy & Security > Accessibility`.
3. Turn off or remove the Send Control entry.
4. Open `System Settings > Privacy & Security > Input Monitoring`.
5. Turn off or remove the Send Control entry.
6. Delete the app if you no longer need it.

## Limits Of This Note

This document describes the current version of Send Control. It is not a legal privacy policy.
