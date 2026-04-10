#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/OpenCue/OpenCue.xcodeproj"
SCHEME="OpenCue"
BUILD_ROOT="$ROOT_DIR/build/local"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/OpenCue.app"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is not available. Install full Xcode first." >&2
  exit 1
fi

DEVELOPER_DIR_PATH="$(xcode-select -p)"
if [[ "$DEVELOPER_DIR_PATH" == "/Library/Developer/CommandLineTools" ]]; then
  echo "error: full Xcode is not active." >&2
  echo "Run: sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

mkdir -p "$BUILD_ROOT"

echo "Building OpenCue (Release) into $DERIVED_DATA_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: build finished but $APP_PATH was not created." >&2
  exit 1
fi

echo "Applying ad-hoc signature for local use"
codesign --force --deep --sign - "$APP_PATH"

echo
echo "OpenCue.app is ready:"
echo "  $APP_PATH"
echo
echo "Next steps:"
echo "  1. Open it directly, or copy it to /Applications"
echo "  2. Optionally package it with ./scripts/make-local-dmg.sh"
