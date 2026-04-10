#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_APP_PATH="$ROOT_DIR/build/local/DerivedData/Build/Products/Release/OpenCue.app"
APP_PATH="${1:-$DEFAULT_APP_PATH}"
DMG_ROOT="$ROOT_DIR/build/dmg"
STAGING_DIR="$DMG_ROOT/staging"
DMG_PATH="$ROOT_DIR/build/OpenCue-local.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found at $APP_PATH" >&2
  echo "Build it first with ./scripts/build-local-release.sh or pass a custom .app path." >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
rm -f "$DMG_PATH"

cp -R "$APP_PATH" "$STAGING_DIR/OpenCue.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating local DMG at $DMG_PATH"
hdiutil create \
  -volname "OpenCue" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo
echo "DMG created:"
echo "  $DMG_PATH"
