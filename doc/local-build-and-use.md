# OpenCue Local Build and Use

This guide is for the current goal: build OpenCue from source, package it locally, and start using it on your own Mac.

It is **not** a notarized Apple distribution flow. For self-use and open-source development, you do not need Developer ID signing, notarization, or a paid Apple Developer account.

## Requirements

- A MacBook with a notch
- macOS 14+
- Xcode 15+ installed in `/Applications/Xcode.app`
- Command line tools pointed at full Xcode:

```bash
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```

## Fastest Path

Build the app:

```bash
./scripts/build-local-release.sh
```

That produces:

```text
build/local/DerivedData/Build/Products/Release/OpenCue.app
```

You can then either:

- open that `.app` directly
- drag it into `/Applications`
- package it into a simple local DMG:

```bash
./scripts/make-local-dmg.sh
```

That produces:

```text
build/OpenCue-local.dmg
```

## First Launch

1. Open `OpenCue.app`.
2. If macOS asks for permission related to keyboard monitoring or accessibility, approve it.
3. If global hotkeys do not work, go to:

```text
System Settings > Privacy & Security > Accessibility
```

Add either:

- `OpenCue.app` if you are running the built app directly
- `Xcode.app` if you are running from Xcode during development

## How To Test It

Use this checklist on a notch Mac:

1. Launch the app.
2. Confirm the main window opens.
3. Confirm the overlay appears in the notch area.
4. Create a folder and a note.
5. Paste a long script into the note.
6. Open Settings and change font size, width, height, and opacity.
7. Confirm the overlay updates live.
8. Press the play button and confirm countdown + scrolling.
9. Test shortcuts:

```text
Cmd+Shift+P   toggle play/pause
Cmd+Up        speed up
Cmd+Down      slow down
Cmd+R         reset
```

10. Record the screen with QuickTime and confirm the overlay is not captured.

## Non-Notch Macs

The current app is built for notch Macs. On a non-notch Mac, the app shows a "Notch Required" alert and skips the overlay if you continue anyway.

## Open-Source vs Notarized Release

For open-source use, this local flow is enough.

You only need the full signing/notarization pipeline if you want to distribute a binary to other people in a way that works cleanly with Gatekeeper.

That later step is still not finished in this repo.
