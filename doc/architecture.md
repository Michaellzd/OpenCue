# OpenCue - Architecture

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (macOS 14+)
- **Storage**: SwiftData (local SQLite under the hood)
- **Build**: Xcode 15+, Swift Package Manager
- **Distribution**: Notarized DMG via `create-dmg` or Xcode archive

## Project Structure

```
OpenCue/
├── OpenCueApp.swift              # App entry point, window group declarations
├── Models/
│   ├── Folder.swift              # SwiftData model
│   ├── Note.swift                # SwiftData model
│   └── AppSettings.swift         # @AppStorage wrapper for all user prefs
├── Views/
│   ├── MainWindow/
│   │   ├── MainContentView.swift # Split view: sidebar + editor
│   │   ├── SidebarView.swift     # Folder/note list
│   │   ├── EditorView.swift      # Text editor pane
│   │   └── ToolbarView.swift     # Play, settings buttons
│   ├── Settings/
│   │   ├── SettingsView.swift    # Settings sheet container (tabs)
│   │   ├── VisualTab.swift       # Appearance controls
│   │   └── GeneralTab.swift      # Scroll & countdown controls
│   └── Teleprompter/
│       ├── TeleprompterWindow.swift   # NSWindow subclass config
│       ├── TeleprompterOverlay.swift  # SwiftUI scrolling text view
│       └── CountdownView.swift        # 3-2-1 countdown overlay
├── Services/
│   ├── NotchDetector.swift       # Detect notch geometry via NSScreen
│   ├── ScrollEngine.swift        # Timer-driven scroll state manager
│   └── HotkeyManager.swift      # Global keyboard shortcut registration
├── Utilities/
│   └── Constants.swift           # App-wide constants, default values
└── Resources/
    └── Assets.xcassets           # App icon, colors
```

## Module Responsibilities

### OpenCueApp (Entry Point)

- Declares two window groups:
  1. **Main Window** - standard `WindowGroup` for content management and settings
  2. **Teleprompter Window** - a borderless, always-on-top, capture-invisible panel
- Injects shared state via `@Environment` and `@StateObject`

### Models

- **Folder**: Has a name, creation date, and a one-to-many relationship with Notes
- **Note**: Has a title, body (plain text), creation date, last-modified date, belongs to one Folder
- **AppSettings**: Wraps `@AppStorage` / `UserDefaults` for all appearance and scroll settings. Single source of truth read by both the main window and the teleprompter overlay.

### Views - MainWindow

- `MainContentView`: `NavigationSplitView` with sidebar (folders/notes) and detail (editor)
- `SidebarView`: List of folders, expandable to show notes. Add/delete/rename via context menu.
- `EditorView`: `TextEditor` for the selected note's body text. Saves on change (debounced).
- `ToolbarView`: Play/Pause button, Settings gear icon.

### Views - Settings

- Presented as a `.sheet` from the main window
- Two tabs: Visual (appearance) and General (scroll/countdown)
- All controls bind directly to `AppSettings` properties

### Views - Teleprompter

- `TeleprompterWindow`: Configures the `NSPanel`/`NSWindow`:
  - `sharingType = .none` (invisible to screen capture)
  - `level = .screenSaver` (above everything)
  - `styleMask = [.borderless]`
  - `isMovable = false`
  - `backgroundColor = .clear` (or user-defined opacity)
  - Positioned using notch coordinates from `NotchDetector`
  - `ignoresMouseEvents = true` during playback
- `TeleprompterOverlay`: Renders the current note's text, scrolls upward driven by `ScrollEngine`
- `CountdownView`: Full-overlay countdown (3, 2, 1) before scroll begins

### Services

- **NotchDetector**: Reads `NSScreen.main?.auxiliaryTopLeftArea` and `auxiliaryTopRightArea` (macOS 14+) to compute the notch rect. Falls back to known notch dimensions per display size if API unavailable.
- **ScrollEngine**: `ObservableObject` with a `Timer.publish` that increments a scroll offset at the configured speed. Exposes `play()`, `pause()`, `reset()`, `setSpeed()`.
- **HotkeyManager**: Registers global hotkeys using `NSEvent.addGlobalMonitorForEvents` or the `HotKey` SPM package. Maps key combos to `ScrollEngine` actions.

## Data Flow

```
User edits note  -->  SwiftData auto-saves
                         |
User taps Play   -->  ScrollEngine starts timer
                         |
                   TeleprompterOverlay observes ScrollEngine.offset
                         |
                   Text view shifts upward each frame
                         |
AppSettings changes -->  TeleprompterOverlay re-renders (font, color, size)
```

## Key Technical Details

### Screen Capture Invisibility

The critical feature. On macOS 12.0+, `NSWindow` has a `sharingType` property:
- `.none` - window is excluded from screen capture, AirPlay, and screenshots
- This is the single API call that makes the teleprompter invisible on Zoom/Meet/Teams

### Notch Positioning

The teleprompter window must be positioned precisely:
- X: Centered on screen, spanning the notch width (or configured width)
- Y: Top of screen (y = screenFrame.maxY - height)
- The window extends below the notch to show the scrolling text
- On notch Macs, the menu bar area around the notch is usable screen space

### Window Behavior

- The teleprompter panel should NOT appear in Mission Control or the Dock
- It should not steal focus from other apps
- `NSPanel` with `.nonactivatingPanel` style mask is ideal for this
- `collectionBehavior` should include `.canJoinAllSpaces` and `.fullScreenAuxiliary`
