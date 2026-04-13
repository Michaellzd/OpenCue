#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_APP_PATH="$ROOT_DIR/build/local/DerivedData/Build/Products/Release/OpenCue.app"
APP_PATH="${1:-$DEFAULT_APP_PATH}"
DMG_ROOT="$ROOT_DIR/build/dmg"
STAGING_DIR="$DMG_ROOT/staging"
RW_DMG_PATH="$DMG_ROOT/OpenCue-local-temp.dmg"
DMG_PATH="$ROOT_DIR/build/OpenCue-local.dmg"
DMG_OUTPUT_BASE="${DMG_PATH%.dmg}"
VOLUME_NAME="OpenCue"
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
WINDOW_LEFT=200
WINDOW_TOP=120
APP_ICON_X=180
APP_ICON_Y=170
APPLICATIONS_ICON_X=480
APPLICATIONS_ICON_Y=170
ICON_SIZE=160

MOUNT_DEVICE=""

cleanup() {
  if [[ -n "$MOUNT_DEVICE" ]]; then
    hdiutil detach "$MOUNT_DEVICE" -quiet >/dev/null 2>&1 || \
      hdiutil detach "$MOUNT_DEVICE" -force -quiet >/dev/null 2>&1 || true
  fi

  rm -rf "$STAGING_DIR"
  rm -f "$RW_DMG_PATH"
}

trap cleanup EXIT

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found at $APP_PATH" >&2
  echo "Build it first with ./scripts/build-local-release.sh or pass a custom .app path." >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
rm -f "$DMG_PATH"
rm -f "$RW_DMG_PATH"

cp -R "$APP_PATH" "$STAGING_DIR/OpenCue.app"
ln -s /Applications "$STAGING_DIR/Applications"

if [[ -d "/Volumes/$VOLUME_NAME" ]]; then
  hdiutil detach "/Volumes/$VOLUME_NAME" -quiet >/dev/null 2>&1 || \
    hdiutil detach "/Volumes/$VOLUME_NAME" -force -quiet >/dev/null 2>&1 || true
fi

STAGING_SIZE_KB="$(du -sk "$STAGING_DIR" | awk '{print $1}')"
DMG_SIZE_KB="$((STAGING_SIZE_KB + 20480))"

echo "Creating local DMG at $DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -size "${DMG_SIZE_KB}k" \
  -ov \
  -format UDRW \
  "$RW_DMG_PATH"

ATTACH_OUTPUT="$(
  hdiutil attach \
    -readwrite \
    -noverify \
    -noautoopen \
    "$RW_DMG_PATH"
)"
MOUNT_DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/Apple_HFS/ {print $1; exit}')"
MOUNT_POINT="/Volumes/$VOLUME_NAME"

if [[ -z "$MOUNT_DEVICE" || ! -d "$MOUNT_POINT" ]]; then
  echo "error: failed to mount writable DMG." >&2
  exit 1
fi

osascript <<OSA
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {$WINDOW_LEFT, $WINDOW_TOP, $(($WINDOW_LEFT + $WINDOW_WIDTH)), $(($WINDOW_TOP + $WINDOW_HEIGHT))}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to $ICON_SIZE
    set text size of viewOptions to 14
    set position of item "OpenCue.app" to {$APP_ICON_X, $APP_ICON_Y}
    set position of item "Applications" to {$APPLICATIONS_ICON_X, $APPLICATIONS_ICON_Y}
    update without registering applications
    delay 2
    close
    open
    delay 1
  end tell
end tell
OSA

chmod -Rf go-w "$MOUNT_POINT"
bless --folder "$MOUNT_POINT" --openfolder "$MOUNT_POINT" >/dev/null 2>&1 || true
sync

hdiutil detach "$MOUNT_DEVICE"
MOUNT_DEVICE=""

hdiutil convert \
  "$RW_DMG_PATH" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_OUTPUT_BASE"

echo
echo "DMG created:"
echo "  $DMG_PATH"
