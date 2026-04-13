#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/OpenCue/OpenCue.xcodeproj/project.pbxproj"
SOURCE_DMG="$ROOT_DIR/build/OpenCue-local.dmg"

if [[ ! -f "$SOURCE_DMG" ]]; then
  echo "error: $SOURCE_DMG does not exist." >&2
  echo "Run ./scripts/make-local-dmg.sh first." >&2
  exit 1
fi

VERSION="$(
  awk -F' = ' '/MARKETING_VERSION = / {
    gsub(/;/, "", $2)
    print $2
    exit
  }' "$PROJECT_FILE"
)"

if [[ -z "$VERSION" ]]; then
  echo "error: failed to read MARKETING_VERSION from $PROJECT_FILE" >&2
  exit 1
fi

VERSIONED_DMG="$ROOT_DIR/build/OpenCue-$VERSION.dmg"
LATEST_DMG="$ROOT_DIR/build/OpenCue.dmg"

cp -f "$SOURCE_DMG" "$VERSIONED_DMG"
cp -f "$SOURCE_DMG" "$LATEST_DMG"

echo "Prepared release assets:"
echo "  $VERSIONED_DMG"
echo "  $LATEST_DMG"
