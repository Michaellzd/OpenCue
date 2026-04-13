# AGENTS.md

This file is the current repo-level guide for coding agents working on OpenCue.

## Project Snapshot

OpenCue is a native macOS teleprompter for notch MacBooks.

Current product shape:

- Main window for folders, notes, and editing
- Separate floating teleprompter panel over the built-in display notch
- Local SwiftData storage
- Local settings stored in `UserDefaults`
- Local build and DMG workflow for self-use

Current branch truth matters more than older planning docs.

## Source Of Truth

Read these first:

1. `README.md`
2. `RELEASING.md` if the task touches versions, packaging, or release work
3. `doc/local-build-and-use.md`
4. `OpenCue/OpenCue/OpenCueApp.swift`
5. `OpenCue/OpenCue/Services/ScrollEngine.swift`
6. `OpenCue/OpenCue/Views/MainWindow/MainContentView.swift`
7. `OpenCue/OpenCue/Views/Teleprompter/TeleprompterWindow.swift`
8. `OpenCue/OpenCue/Views/Teleprompter/TeleprompterOverlay.swift`

Treat older planning docs in `doc/prd.md`, `doc/architecture.md`, and `doc/agents/*.md` as historical context unless the current code still matches them.

## Current Product Rules

- The teleprompter panel should stay hidden until playback starts.
- `Play` starts scrolling immediately. Countdown is not part of the current UX.
- The main note flow must be obvious. Do not regress back to a context-menu-only creation flow.
- Scroll speed comes from settings and must stay in sync with playback behavior.
- Overlay controls currently include pause/resume and close.
- The app is notch-first. External displays and non-notch Macs are not the target path.

## Capture-Invisibility Guidance

- The panel uses `NSWindow.sharingType = .none`.
- Do not write docs or marketing copy that claims universal invisibility across all screen capture or call tools.
- Phrase it as best-effort behavior and require real-world testing with specific apps.

## Build And Verification

Preferred local build:

```bash
./scripts/build-local-release.sh
```

If needed:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build-local-release.sh
```

Simple local packaging:

```bash
./scripts/make-local-dmg.sh
```

When testing UI changes, remember that reopening the same bundle ID can reactivate an already-running app. Fully quit `OpenCue` before assuming a new build is the one on screen.

## Editing Guidance

- Keep README and operational docs aligned with the real app, not the idealized roadmap.
- If you change playback, settings, or capture wording, update `README.md` and `doc/local-build-and-use.md` in the same pass.
- Prefer clarifying current constraints over promising unfinished distribution work.
- Do not introduce countdown UX again unless explicitly requested.

## Distribution Guidance

- The repo supports local self-use today.
- Full Developer ID signing, notarization, and polished public distribution are still unfinished.
- If you work on release engineering, document blockers precisely instead of hand-waving around them.
- For all release work, use `RELEASING.md` as the process source of truth.
