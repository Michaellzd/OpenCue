# OpenCue - Product Requirements Document

## Overview

OpenCue is a native macOS teleprompter app that sits inside the MacBook notch. It is invisible to screen capture APIs, so the audience on Zoom/Meet/Teams never sees it. Users paste their scripts, organize them in folders, and scroll through them while recording.

## Target User

Content creators, presenters, and professionals who record video or do live calls and want to read from a script without it being visible to the audience.

## Platform Constraints

- macOS 14+ (Sonoma) - required for modern SwiftUI APIs and notch detection
- Apple Silicon and Intel Macs **with a built-in notch display only**
- No support for external monitors or non-notch Macs in MVP

## Distribution

- Direct download, notarized DMG
- No Mac App Store (avoids sandbox restrictions)
- Requires code signing with Developer ID

## Core Features

### F1: Notch Teleprompter Overlay

- A floating overlay window positioned exactly over the Mac's notch area
- Extends downward from the notch to display scrolling text
- Uses `window.sharingType = .none` to be invisible to screen capture
- Window level above all other windows
- Does not capture mouse/keyboard focus unless explicitly interacted with
- Click-through when scrolling (does not interfere with other apps)

### F2: Script/Content Management

- **Folders**: User creates folders to organize scripts by project/video
- **Notes**: Each folder contains notes (scripts). A note has a title and body text
- **Editor**: Simple plain-text editor in the main window for writing/pasting scripts
- CRUD operations for both folders and notes
- Last-opened note is remembered on relaunch

### F3: Appearance Settings

| Setting | Type | Range/Options | Default |
|---------|------|---------------|---------|
| Font Size | Slider | 12-36 pt | 19 |
| Width | Slider | 200-500 px | 300 |
| Height | Slider | 80-300 px | 130 |
| Opacity | Slider | 50-100% | 95% |
| Text Alignment | Segmented | Left, Center, Right, Justified | Center |
| Text Color | Color picker | Any | Black |
| Rich Text Formatting | Toggle | On/Off | On |
| Collapse Empty Lines | Toggle | On/Off | Off |

### F4: Scroll & Playback

| Setting | Type | Range/Options | Default |
|---------|------|---------------|---------|
| Scroll Speed | Slider | 1-10 | 3 |
| Countdown Before Start | Toggle | On/Off | On |
| Countdown Duration | Slider | 1-10 s | 3 |

- Play/Pause button in the main window toolbar
- Countdown overlay displayed in the notch window before scrolling starts
- Smooth, constant-speed auto-scroll
- Scroll resets to top when a new note is selected

### F5: Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Play / Pause | Space (when main window focused) or global hotkey Cmd+Shift+P |
| Speed Up | Cmd+Up |
| Speed Down | Cmd+Down |
| Reset to Top | Cmd+R |

## Out of Scope (MVP)

- iCloud sync
- External monitor / non-notch Mac support
- Export/import of notes
- Mirror/flip mode
- Speech-tracking (auto-scroll by voice)
- Mac App Store distribution
