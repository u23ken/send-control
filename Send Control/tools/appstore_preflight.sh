#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/IMEFix.xcodeproj"
DERIVED_DATA_PATH="/tmp/IMEFixDerived"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Send Control.app"
BIN_PATH="$APP_PATH/Contents/MacOS/SendControl"

fail_count=0

pass() {
  echo "[PASS] $1"
}

fail() {
  echo "[FAIL] $1"
  fail_count=$((fail_count + 1))
}

echo "== Build =="
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme IMEFix \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build >/tmp/sendcontrol_preflight_build.log 2>&1 || {
  tail -n 80 /tmp/sendcontrol_preflight_build.log
  fail "Release build failed."
  echo "Preflight failed with $fail_count issue(s)."
  exit 1
}
pass "Release build succeeded."

if [[ ! -d "$APP_PATH" ]]; then
  fail "Built app bundle not found at expected path: $APP_PATH"
  echo "Preflight failed with $fail_count issue(s)."
  exit 1
fi

echo "== Entitlements =="
entitlements_output="$(codesign -d --entitlements :- "$APP_PATH" 2>&1 || true)"
if echo "$entitlements_output" | grep -q "com.apple.security.app-sandbox"; then
  pass "App Sandbox entitlement present."
else
  fail "App Sandbox entitlement missing."
fi

echo "== Bundle Identifier =="
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "$bundle_id" ]]; then
  fail "Bundle identifier missing."
elif [[ "$bundle_id" == com.example.* ]]; then
  fail "Bundle identifier is still placeholder ($bundle_id)."
else
  pass "Bundle identifier is non-placeholder ($bundle_id)."
fi

echo "== Code Signing =="
codesign_output="$(codesign -dv "$APP_PATH" 2>&1 || true)"
if echo "$codesign_output" | grep -q "TeamIdentifier=not set"; then
  fail "Team identifier is not set (local ad-hoc signing)."
else
  pass "Team identifier is set."
fi

echo "== Binary Privacy Strings =="
if [[ ! -f "$BIN_PATH" ]]; then
  fail "Executable not found: $BIN_PATH"
else
  if strings "$BIN_PATH" | grep -E -q "Callback #|frontmost=|keyCode=|Return detected:"; then
    fail "Found verbose key-event diagnostics in binary."
  else
    pass "No verbose key-event diagnostic strings detected."
  fi
fi

echo
if [[ $fail_count -eq 0 ]]; then
  echo "Preflight passed with 0 issues."
else
  echo "Preflight failed with $fail_count issue(s)."
  exit 1
fi
