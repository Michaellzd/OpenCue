# CLAUDE.md

This file mirrors the repo guidance in `AGENTS.md` for Claude-style tooling.

## Project Snapshot

OpenCue is a native macOS teleprompter for notch MacBooks.

Current product shape:

- Main window for folders, notes, and editing
- Separate floating teleprompter panel over the built-in display notch
- Local SwiftData storage
- Local settings stored in `UserDefaults`
- Local build and DMG workflow for self-use

Current branch truth matters more than older planning docs.

## Read First

1. `README.md`
2. `doc/local-build-and-use.md`
3. `OpenCue/OpenCue/OpenCueApp.swift`
4. `OpenCue/OpenCue/Services/ScrollEngine.swift`
5. `OpenCue/OpenCue/Views/MainWindow/MainContentView.swift`
6. `OpenCue/OpenCue/Views/Teleprompter/TeleprompterWindow.swift`
7. `OpenCue/OpenCue/Views/Teleprompter/TeleprompterOverlay.swift`

Use `doc/prd.md`, `doc/architecture.md`, and `doc/agents/*.md` as historical planning material unless the live code still reflects them.

## Current Product Rules

- The teleprompter panel stays hidden until playback starts.
- `Play` starts scrolling immediately. Countdown is not part of the current UX.
- The note creation path must remain obvious and discoverable.
- Scroll speed in settings must match actual playback speed.
- Overlay controls include pause/resume and close.
- The app is designed for notch Macs, not external displays or non-notch Macs.

## Capture-Invisibility Guidance

- The app uses `NSWindow.sharingType = .none`.
- Do not describe this as a universal guarantee for every recording, conferencing, or capture tool.
- Document it as best-effort behavior and insist on app-by-app testing.

## Build And Verification

Preferred local build:

```bash
./scripts/build-local-release.sh
```

If `xcode-select` is wrong, use:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build-local-release.sh
```

Local packaging:

```bash
./scripts/make-local-dmg.sh
```

When validating UI changes, quit the running `OpenCue` app before reopening a rebuilt binary. macOS can otherwise reactivate the old process and make the test result misleading.

## Editing Guidance

- Keep documentation grounded in the current implementation.
- Update `README.md` and `doc/local-build-and-use.md` whenever core behavior changes.
- Avoid reintroducing countdown UX unless explicitly requested.
- Be precise about what is finished versus what is still release-engineering work.

## Distribution Guidance

- Local source builds are the supported path today.
- Full signing, notarization, and public DMG release automation are still incomplete.
- When blocked on Apple credentials or release setup, document the blocker clearly instead of pretending the distribution path exists.
