# OpenCue

OpenCue is a native macOS teleprompter for notch MacBooks. It gives you a normal script editor in the main window and a separate floating teleprompter panel aligned to the built-in display notch.

The current goal for this repo is straightforward: keep the project easy to build from source, easy to test on a real Mac, and ready to publish as an open-source project.

## Current Status

- Works as a local source build on macOS 14+ with Xcode 15+
- Built for MacBooks with a built-in notch
- Stores folders, notes, and user settings locally
- Includes a local `.app` and simple `.dmg` workflow for self-use
- Does not yet include a finished Developer ID signing + notarization pipeline

## What The App Does

- Organizes scripts into folders and notes
- Opens directly into a plain text editing workflow
- Shows the teleprompter panel only during playback states
- Supports live visual settings for width, height, opacity, font size, alignment, and text color
- Supports adjustable scroll speed, pause/resume, reset, and keyboard shortcuts

## Important Caveats

- OpenCue is notch-first. External monitors and non-notch Macs are not the target setup.
- The teleprompter panel uses `NSWindow.sharingType = .none` as a best-effort capture-avoidance technique.
- Do not market or document this as a universal guarantee that every screen recording or screen sharing tool will hide the panel.
- If capture invisibility matters for your workflow, test it with the exact tools you use, such as QuickTime, Zoom, Meet, OBS, or Loom.

## Build And Run

Requirements:

- macOS 14+
- A MacBook with a built-in notch
- Full Xcode installed at `/Applications/Xcode.app`

Build a local Release app:

```bash
./scripts/build-local-release.sh
```

If `xcode-select` still points at Command Line Tools, either switch it:

```bash
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```

or run the script with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

The built app ends up at:

```text
build/local/DerivedData/Build/Products/Release/OpenCue.app
```

To package a simple local DMG:

```bash
./scripts/make-local-dmg.sh
```

## Use It

1. Launch `OpenCue.app`.
2. Create a folder if the sidebar is empty.
3. Create or select a note.
4. Paste or write your script.
5. Adjust visual settings and scroll speed.
6. Press `Play` to show the teleprompter and start scrolling immediately.

Keyboard shortcuts:

- `Cmd+Shift+P`: play / pause
- `Cmd+Up`: increase speed
- `Cmd+Down`: decrease speed
- `Cmd+R`: reset to top

## Testing Checklist

Use a real notch Mac and verify:

1. The main window opens normally.
2. You can create folders and notes without using a context-menu-only flow.
3. The editor accepts title and body text immediately.
4. The teleprompter stays hidden until playback starts.
5. A long note actually scrolls.
6. The overlay pause/play button and close button both work.
7. Settings update the overlay live.
8. Your preferred recording or call tools do or do not capture the overlay as expected.

## Repo Guide

- [doc/local-build-and-use.md](./doc/local-build-and-use.md): current local build and test path
- [doc/README.md](./doc/README.md): documentation index
- [AGENTS.md](./AGENTS.md): repo guidance for coding agents
- [CLAUDE.md](./CLAUDE.md): same project guidance for Claude-style tooling

## About The Docs

The planning docs under `doc/` are still useful, but some of them describe earlier design phases, including countdown-based playback and stronger capture-invisibility wording than we should use now.

Treat these as the current source of truth:

- this `README.md`
- `doc/local-build-and-use.md`
- `AGENTS.md`
- `CLAUDE.md`
