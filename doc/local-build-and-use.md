# OpenCue Local Build and Use

This is the current practical path for OpenCue: build from source, run it on your own Mac, and test the workflow end to end.

It is not the full Apple distribution path. You do not need Developer ID signing or notarization for local self-use.

## Requirements

- macOS 14+
- A MacBook with a built-in notch
- Xcode 15+ installed at `/Applications/Xcode.app`

If `xcode-select` still points at Command Line Tools, switch it:

```bash
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```

You can also leave `xcode-select` alone and run the build script with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Fastest Path

Build the app:

```bash
./scripts/build-local-release.sh
```

That produces:

```text
build/local/DerivedData/Build/Products/Release/OpenCue.app
```

Optional local packaging:

```bash
./scripts/make-local-dmg.sh
```

That produces:

```text
build/OpenCue-local.dmg
```

## First Launch

1. Open `OpenCue.app`.
2. If macOS asks for accessibility-related permission for keyboard monitoring, approve it.
3. If global hotkeys do not work, go to:

```text
System Settings > Privacy & Security > Accessibility
```

Add either:

- `OpenCue.app` if you are running the built app directly
- `Xcode.app` if you are running from Xcode during development

## How To Test It

Use a real notch Mac and verify:

1. Launch the app.
2. Confirm the main window opens.
3. Confirm the teleprompter is hidden before playback.
4. Create a folder and a note.
5. Paste a long script into the note.
6. Confirm the title field and body editor both work immediately.
7. Open Settings and change font size, width, height, opacity, alignment, and speed.
8. Confirm the overlay updates live.
9. Press `Play` and confirm scrolling starts immediately.
10. Confirm the overlay pause/resume and close controls work.
11. Test shortcuts:

```text
Cmd+Shift+P   toggle play/pause
Cmd+Up        speed up
Cmd+Down      slow down
Cmd+R         reset
```

## Capture Testing

The panel currently uses `NSWindow.sharingType = .none`, but you should treat capture invisibility as something to verify, not assume.

Test with the exact tools you care about, for example:

- QuickTime
- Zoom
- Google Meet
- OBS
- Loom

## Non-Notch Macs

The app is built for notch Macs. On a non-notch Mac, it shows a "Notch Required" alert and lets you continue without the teleprompter overlay.

## Open-Source vs Notarized Release

For source-first use and local development, this flow is enough.

If you want a polished public binary release, the missing work is still:

- Developer ID signing
- notarization
- public DMG distribution flow
