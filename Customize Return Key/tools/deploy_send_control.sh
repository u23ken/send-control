#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/IMEFix.xcodeproj"
SCHEME_NAME="IMEFix"
DERIVED_DATA_PATH="/tmp/IMEFixDerived"
BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Send Control.app"
TARGET_APP_PATH="/Applications/Send Control.app"

skip_build=0
open_after_install=1
reset_permissions=0
for arg in "$@"; do
  case "$arg" in
    --skip-build) skip_build=1 ;;
    --no-open) open_after_install=0 ;;
    --fresh-permissions) reset_permissions=1 ;;
    --keep-permissions) reset_permissions=0 ;;
    --help)
      cat <<'EOF'
Usage: deploy_send_control.sh [options]
  --skip-build          Skip xcodebuild and deploy existing Release build
  --no-open             Do not launch app after install
  --fresh-permissions   Reset Accessibility/Input Monitoring (simulate first install)
  --keep-permissions    Keep existing permissions (default)
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$skip_build" -eq 0 ]]; then
  echo "== Building Release app =="
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
fi

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Built app not found: $BUILT_APP_PATH" >&2
  exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
  relay_args=(--skip-build)
  if [[ "$open_after_install" -eq 0 ]]; then
    relay_args+=(--no-open)
  fi
  if [[ "$reset_permissions" -eq 1 ]]; then
    relay_args+=(--fresh-permissions)
  fi
  exec sudo "$0" "${relay_args[@]}"
fi

user_home="/Users/$SUDO_USER"
if [[ -z "${SUDO_USER:-}" || ! -d "$user_home" ]]; then
  user_home="/Users/ken"
fi

echo "== Stopping running instances =="
pkill -9 "Send Control" >/dev/null 2>&1 || true
pkill -9 "IMEFix" >/dev/null 2>&1 || true

echo "== Removing old app copies =="
rm -rf "$TARGET_APP_PATH"
rm -rf "/Applications/IMEFix.app"
rm -rf "$user_home/Applications/Send Control.app"
rm -rf "$user_home/Applications/IMEFix.app"

echo "== Installing latest app =="
cp -R "$BUILT_APP_PATH" "$TARGET_APP_PATH"

if [[ "$reset_permissions" -eq 1 ]]; then
  echo "== Resetting TCC permissions (fresh-install simulation) =="
  run_as_user=( )
  if [[ -n "${SUDO_USER:-}" ]]; then
    run_as_user=(sudo -u "$SUDO_USER")
  fi

  bundle_ids=("com.sendcontrol.app" "com.example.IMEFix")
  services=("Accessibility" "ListenEvent")
  for bundle_id in "${bundle_ids[@]}"; do
    for service in "${services[@]}"; do
      if "${run_as_user[@]}" tccutil reset "$service" "$bundle_id" >/dev/null 2>&1; then
        echo "Reset: $service / $bundle_id"
      else
        echo "Warning: failed to reset $service / $bundle_id"
      fi
    done
  done
fi

if [[ "$reset_permissions" -eq 0 ]]; then
  echo "== Keeping existing TCC permissions =="
fi

echo "Installed: $TARGET_APP_PATH"
stat -f "%Sm %N" -t "%Y-%m-%d %H:%M:%S" "$TARGET_APP_PATH/Contents/MacOS/Send Control"

if [[ "$open_after_install" -eq 1 ]]; then
  if [[ -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" open "$TARGET_APP_PATH"
  else
    open "$TARGET_APP_PATH"
  fi
fi
