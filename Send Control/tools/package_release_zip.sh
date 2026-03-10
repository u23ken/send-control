#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Send Control.xcodeproj"
SCHEME_NAME="Send Control"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/SendControlReleaseAsset}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Send Control.app"
OUTPUT_ROOT="${OUTPUT_ROOT:-$ROOT_DIR/dist/release}"
ZIP_BASENAME="Send.Control.app.zip"
SHA_BASENAME="SHA256SUMS.txt"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "Required tool not found: $1"
}

verify_app_bundle() {
  local app_path="$1"
  local context="$2"
  local codesign_output

  [[ -d "$app_path" ]] || fail "$context: app bundle not found: $app_path"

  codesign_output="$(codesign -dv "$app_path" 2>&1 || true)"
  if [[ "$codesign_output" == *"code object is not signed at all"* ]]; then
    fail "$context: app bundle is not signed."
  fi
  if [[ "$codesign_output" == *"Info.plist=not bound"* ]]; then
    fail "$context: Info.plist is not bound into the signature."
  fi
  if [[ "$codesign_output" != *"Identifier=com.sendcontrol.app"* ]]; then
    fail "$context: unexpected bundle identifier in signature."
  fi
  if [[ "$codesign_output" != *"Sealed Resources version="* ]]; then
    fail "$context: sealed resources are missing."
  fi

  local plist_path="$app_path/Contents/Info.plist"
  local bundle_id
  bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist_path" 2>/dev/null || true)"
  [[ "$bundle_id" == "com.sendcontrol.app" ]] || fail "$context: unexpected CFBundleIdentifier ($bundle_id)."
}

require_tool xcodebuild
require_tool codesign
require_tool ditto
require_tool unzip
require_tool shasum

echo "== Building Release app =="
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

verify_app_bundle "$APP_PATH" "post-build"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
artifact_dir="$OUTPUT_ROOT/v${version}-build${build_number}"
zip_path="$artifact_dir/$ZIP_BASENAME"
sha_path="$artifact_dir/$SHA_BASENAME"

mkdir -p "$artifact_dir"
rm -f "$zip_path" "$sha_path"
rm -rf "$artifact_dir/unpacked"

echo "== Packaging zip =="
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$zip_path"

echo "== Verifying packaged zip =="
unzip -q "$zip_path" -d "$artifact_dir/unpacked"
verify_app_bundle "$artifact_dir/unpacked/Send Control.app" "post-unzip"
rm -rf "$artifact_dir/unpacked"

(
  cd "$artifact_dir"
  shasum -a 256 "$ZIP_BASENAME" > "$SHA_BASENAME"
)

echo
echo "Release asset ready:"
echo "  version: $version"
echo "  build:   $build_number"
echo "  zip:     $zip_path"
echo "  sha256:  $sha_path"
