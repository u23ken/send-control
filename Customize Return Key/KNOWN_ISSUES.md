# Known Issues

Japanese KNOWN_ISSUES: [KNOWN_ISSUES.ja.md](KNOWN_ISSUES.ja.md)

## Packaging And Launch

- This technical preview is not notarized. First launch requires manual Gatekeeper approval.
- If `/Applications/Send Control.app` already exists, launching a preview copy from another folder can redirect to the installed app instead.
- Only one instance with the same bundle identifier can run at a time. A second copy exits.

## Permissions

- Accessibility and Input Monitoring are both required. If either permission is missing, the event tap remains OFF.
- After changing permission settings, you may need to quit and relaunch the app before protection becomes active.

## Support Expectations

- This package is aimed at testers, not general users.
- There is no installer, updater, or notarized distribution flow in this technical preview.
- If behavior differs across macOS versions or target apps, exact reproduction details are needed to evaluate the report.
