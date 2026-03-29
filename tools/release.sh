#!/usr/bin/env bash
set -euo pipefail

# Release build, sign, notarize, and package Send Control.
#
# Prerequisites:
#   1. Apple Developer Program membership
#   2. Developer ID Application certificate installed in Keychain
#   3. App-specific password stored: xcrun notarytool store-credentials "SendControl"
#
# Usage:
#   ./tools/release.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/SendControl.xcodeproj"
SCHEME_NAME="SendControl"
DERIVED_DATA_PATH="/tmp/SendControlRelease"
BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Send Control.app"
OUTPUT_DIR="$ROOT_DIR/dist"

# --- Configuration (update after Developer Program enrollment) ---
SIGNING_IDENTITY="Developer ID Application: Kensuke Utsumi (MBAS8P8RVL)"
KEYCHAIN_PROFILE="SendControl"
# ----------------------------------------------------------------

echo "== Step 1: Clean build =="
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Error: Built app not found at $BUILT_APP_PATH" >&2
  exit 1
fi

echo "== Step 2: Code sign =="
if [[ "$SIGNING_IDENTITY" == *"YOUR_NAME"* ]]; then
  echo "WARNING: Using placeholder signing identity."
  echo "Update SIGNING_IDENTITY in this script after enrolling in Apple Developer Program."
  echo "Skipping signing, notarization, and stapling."
  echo ""
else
  codesign --force --deep --options runtime \
    --sign "$SIGNING_IDENTITY" \
    "$BUILT_APP_PATH"

  echo "== Step 3: Create ZIP for notarization =="
  mkdir -p "$OUTPUT_DIR"
  NOTARIZE_ZIP="$OUTPUT_DIR/Send Control-notarize.zip"
  ditto -c -k --keepParent "$BUILT_APP_PATH" "$NOTARIZE_ZIP"

  echo "== Step 4: Submit for notarization =="
  xcrun notarytool submit "$NOTARIZE_ZIP" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

  echo "== Step 5: Staple notarization ticket =="
  xcrun stapler staple "$BUILT_APP_PATH"

  rm -f "$NOTARIZE_ZIP"
fi

echo "== Step 6: Create distribution ZIP =="
mkdir -p "$OUTPUT_DIR"
VERSION=$(defaults read "$BUILT_APP_PATH/Contents/Info.plist" CFBundleShortVersionString)
RELEASE_ZIP="$OUTPUT_DIR/Send-Control-v${VERSION}.zip"
ditto -c -k --keepParent "$BUILT_APP_PATH" "$RELEASE_ZIP"

echo "== Step 7: Generate checksum =="
CHECKSUM_FILE="$OUTPUT_DIR/SHA256SUMS.txt"
(cd "$OUTPUT_DIR" && shasum -a 256 "$(basename "$RELEASE_ZIP")") > "$CHECKSUM_FILE"

echo ""
echo "=== Release artifacts ==="
echo "  ZIP: $RELEASE_ZIP"
echo "  SHA: $CHECKSUM_FILE"
cat "$CHECKSUM_FILE"
echo ""
echo "Upload these files to GitHub Releases."
