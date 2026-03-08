# Send Control Privacy Notes

## What Send Control Monitors

Send Control installs a macOS session event tap after you grant permission. In the current source tree, it monitors:

- global `keyDown` and `keyUp` keyboard events,
- only Return (`keyCode 36`) and keypad Enter (`keyCode 76`) as remap candidates,
- modifier flags needed to preserve Command, Control, and Option behavior and to distinguish Shift+Return,
- the frontmost app bundle identifier needed to decide whether to remap the key event.

## What Send Control Does Not Store

Based on the current source tree, Send Control does not save:

- typed text,
- message contents,
- a keystroke history,
- clipboard contents,
- screenshots,
- a list of the apps you used,
- network analytics or cloud data.

The current source tree does persist one local preference: whether protection was last left ON or OFF. macOS may also keep its own permission records and unified logs. This package does not add its own separate telemetry or sync service.

## What Send Control Sends

No network sending logic was found in the current source tree during this packaging pass.

## How To Remove Permissions

To revoke Send Control permissions:

1. Quit the app.
2. Open `System Settings > Privacy & Security > Accessibility`.
3. Turn off or remove the Send Control entry.
4. Open `System Settings > Privacy & Security > Input Monitoring`.
5. Turn off or remove the Send Control entry.
6. Delete the app if you no longer need it.

## Limits Of This Note

This document is a packaging note for the current repository state on 2026-03-08. It is not a legal privacy policy and it does not cover future builds.
