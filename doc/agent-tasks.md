# OpenCue - Agent Task Assignments

This document defines discrete agent tasks for building OpenCue. Each agent is self-contained with required reading, explicit deliverables, and a checklist. Agents in the same round can run in parallel with no conflicts.

**Important for all agents:**
- Read the listed docs before writing any code
- The Xcode project lives at `OpenCue/` in the repo root
- Target: macOS 14+ (Sonoma), Swift 5.9+, SwiftUI
- Follow the file structure defined in `doc/architecture.md`
- Do not modify files outside your listed deliverables unless necessary for compilation
- Light theme, Apple HIG style, SF Pro system font

---

## Round 1 — Foundation (Parallel)

### Agent A: Project Scaffold + Notch Teleprompter Window

**Read first**: `doc/architecture.md`, `doc/ui-spec.md` (Teleprompter Overlay section)

**Goal**: Create the Xcode project and get a borderless, capture-invisible floating panel showing static text positioned over the Mac's notch.

**Deliverables**:
- `OpenCue.xcodeproj` (SwiftUI App, macOS 14+ deployment target)
- `OpenCue/OpenCueApp.swift` — App entry point. For now, declare a single main `WindowGroup`. Set up the teleprompter panel programmatically via `NSApplication` lifecycle.
- `OpenCue/Services/NotchDetector.swift` — Detect notch geometry from `NSScreen.main`. Compute the rect where the notch lives. Export the notch center X, width, and Y position.
- `OpenCue/Views/Teleprompter/TeleprompterWindow.swift` — `NSPanel` subclass or configuration with:
  - `sharingType = .none`
  - `styleMask = [.borderless, .nonactivatingPanel]`
  - `level = .screenSaver` (or `.statusBar + 1`)
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
  - `isMovable = false`
  - `hidesOnDeactivate = false`
  - `ignoresMouseEvents = true`
  - `backgroundColor = .white.withAlphaComponent(0.95)`
  - Positioned using `NotchDetector` output
- `OpenCue/Views/Teleprompter/TeleprompterOverlay.swift` — SwiftUI view hosted in the panel. For now, display a hardcoded multi-line string. Text should be centered, white background, system font 19pt.
- `OpenCue/Utilities/Constants.swift` — Default values (width: 300, height: 130, opacity: 0.95, fontSize: 19)

**Checklist**:
- [ ] Xcode project builds and runs on macOS 14+
- [ ] A floating panel appears over the notch area showing static text
- [ ] Panel is borderless with no title bar, no shadow, no traffic lights
- [ ] Panel stays on top of all other windows
- [ ] Panel does not appear in Mission Control or Dock
- [ ] Panel does not steal focus from other apps
- [ ] Panel is invisible when doing a QuickTime screen recording (sharingType = .none)
- [ ] NotchDetector correctly computes notch position
- [ ] Panel width and height match defaults (300x130)

---

### Agent B: Data Model + Content Management UI

**Read first**: `doc/data-model.md`, `doc/architecture.md`, `doc/ui-spec.md` (Main Window section)

**Goal**: Build the main window with folder/note management and a text editor. All data persists locally via SwiftData.

**Deliverables**:
- `OpenCue/Models/Folder.swift` — SwiftData `@Model` with id, name, createdAt, sortOrder, cascade-delete relationship to Notes
- `OpenCue/Models/Note.swift` — SwiftData `@Model` with id, title, body, createdAt, updatedAt, relationship to Folder
- `OpenCue/Views/MainWindow/MainContentView.swift` — `NavigationSplitView` composing SidebarView and EditorView
- `OpenCue/Views/MainWindow/SidebarView.swift`:
  - List of folders as expandable `DisclosureGroup`s
  - Notes listed under each folder (title only)
  - "+ New Folder" button at bottom
  - Context menus: Rename, Delete on folders; Rename, Delete on notes; Add Note on folders
  - Selection binding to load note in editor
- `OpenCue/Views/MainWindow/EditorView.swift`:
  - Editable title field (large, top of pane)
  - `TextEditor` for body text (fills remaining space)
  - Auto-save: debounce 500ms after typing stops, write to SwiftData
  - Word count label at bottom-right
  - Empty state: "Select or create a note"
- Update `OpenCueApp.swift`:
  - Register `ModelContainer` for Folder and Note
  - Inject into environment
  - Set main window default size 800x550, min 600x400

**Checklist**:
- [ ] App launches showing a split view (sidebar + editor)
- [ ] User can create a new folder
- [ ] User can rename a folder via context menu
- [ ] User can delete a folder (cascades to its notes)
- [ ] User can add a note inside a folder
- [ ] User can rename a note via context menu
- [ ] User can delete a note
- [ ] Selecting a note loads its title and body in the editor
- [ ] Editing title or body auto-saves after 500ms debounce
- [ ] Data persists across app relaunch
- [ ] Last-opened note is restored on relaunch (store note ID in UserDefaults)
- [ ] Empty states display correctly (no folders, no note selected)
- [ ] Sidebar is ~220px wide
- [ ] UI is clean, light theme, Apple-style spacing and typography

---

## Round 2 — Core Features (Parallel)

> **Prerequisite**: Round 1 (Agent A + B) must be complete. Agent C and D work on the merged codebase.

### Agent C: Scroll Engine + Playback

**Read first**: `doc/architecture.md` (ScrollEngine, TeleprompterOverlay sections), `doc/prd.md` (F4: Scroll & Playback), `doc/ui-spec.md` (Overlay states)

**Goal**: Make the teleprompter overlay display the selected note's text and scroll it smoothly. Add play/pause controls and a countdown.

**Deliverables**:
- `OpenCue/Services/ScrollEngine.swift`:
  - `ObservableObject` with `@Published offset: CGFloat`
  - Timer-based (use `TimelineView` or `CADisplayLink` for 60fps smoothness)
  - Methods: `play()`, `pause()`, `reset()`, `setSpeed(_ speed: Double)`
  - `@Published state: ScrollState` enum: `.idle`, `.countdown`, `.playing`, `.paused`, `.finished`
  - Speed is pixels-per-frame derived from the 1-10 speed scale
- Update `OpenCue/Views/Teleprompter/TeleprompterOverlay.swift`:
  - Replace hardcoded text with the currently selected note's body
  - Apply scroll offset to shift text upward
  - Detect when text has fully scrolled past → set state to `.finished`
- `OpenCue/Views/Teleprompter/CountdownView.swift`:
  - Displays 3... 2... 1... with scale/fade animation
  - Each number shown for 1 second
  - After countdown completes, triggers `ScrollEngine.play()`
- Update `OpenCue/Views/MainWindow/ToolbarView.swift` (or add toolbar items to MainContentView):
  - Play/Pause toggle button in toolbar (SF Symbol: `play.fill` / `pause.fill`)
  - Button is blue-filled when playing
  - Disabled when no note is selected
- Wire up shared state:
  - The main window and teleprompter overlay both observe the same `ScrollEngine` instance
  - When user selects a different note, call `ScrollEngine.reset()`
  - When user taps Play: if countdown enabled → show countdown → then scroll. If disabled → scroll immediately.

**Checklist**:
- [ ] Teleprompter overlay shows the currently selected note's text
- [ ] Tapping Play starts a 3-2-1 countdown in the overlay
- [ ] After countdown, text scrolls upward smoothly
- [ ] Tapping Pause stops scrolling, tapping Play resumes
- [ ] Scroll speed matches the default (3 on 1-10 scale)
- [ ] Switching notes resets scroll to top
- [ ] Scroll stops automatically when text reaches the end
- [ ] Play button is disabled when no note is selected
- [ ] Play button visually indicates playing state (blue fill)
- [ ] Countdown animation is smooth (scale + fade)
- [ ] Scrolling is smooth at 60fps, no jank

---

### Agent D: Settings UI + AppSettings

**Read first**: `doc/data-model.md` (UserDefaults Keys), `doc/prd.md` (F3: Appearance, F4: Scroll), `doc/ui-spec.md` (Settings Sheet)

**Goal**: Build the settings sheet with all appearance and scroll controls. All settings are reactive and immediately applied.

**Deliverables**:
- `OpenCue/Models/AppSettings.swift`:
  - `ObservableObject` class (singleton or environment object)
  - All properties use `@AppStorage` with `opencue.` prefix keys
  - Properties: fontSize, overlayWidth, overlayHeight, opacity, textAlignment, textColorData, richTextEnabled, collapseEmptyLines, scrollSpeed, countdownEnabled, countdownDuration
  - Computed property for `textColor` that encodes/decodes `NSColor` ↔ `Data`
  - Computed property for `textAlignmentValue` that maps String ↔ `TextAlignment`
- `OpenCue/Views/Settings/SettingsView.swift`:
  - Modal sheet (`.sheet` presentation)
  - Top: "Settings" title + close button (X)
  - Segmented picker toggling between Visual and General tabs
  - 450x500 fixed size
- `OpenCue/Views/Settings/VisualTab.swift`:
  - **Appearance section** (GroupBox):
    - Font Size slider (12-36, step 1, shows current value)
    - Width slider (200-500, step 10, shows "Npx")
    - Height slider (80-300, step 10, shows "Npx")
    - Opacity slider (50-100%, step 5, shows "N%")
    - Text Alignment segmented picker (Left/Center/Right/Justified)
  - **Formatting section** (GroupBox):
    - Rich Text Formatting toggle (checkbox)
    - Collapse Empty Lines toggle (checkbox)
    - Text Color picker
- `OpenCue/Views/Settings/GeneralTab.swift`:
  - **Scroll section** (GroupBox):
    - Scroll Speed slider (1-10, step 1, shows current value)
  - **Countdown section** (GroupBox):
    - Countdown Before Start toggle (checkbox)
    - Countdown Duration slider (1-10, step 1, shows "Ns") — disabled when toggle is off
- Wire settings to teleprompter overlay:
  - Overlay reads `AppSettings` for font size, width, height, opacity, alignment, text color
  - `ScrollEngine` reads `AppSettings` for scroll speed
  - Countdown reads `AppSettings` for enabled/duration
  - All changes apply in real-time (no save/apply button)
- Add settings gear button to main window toolbar (SF Symbol: `gearshape`) that opens the sheet

**Checklist**:
- [ ] Gear icon in toolbar opens settings sheet
- [ ] Settings sheet has Visual and General tabs via segmented control
- [ ] Visual tab: Font Size slider works and shows current value
- [ ] Visual tab: Width slider works, overlay resizes in real-time
- [ ] Visual tab: Height slider works, overlay resizes in real-time
- [ ] Visual tab: Opacity slider works, overlay opacity changes in real-time
- [ ] Visual tab: Text Alignment picker works, overlay text alignment changes
- [ ] Visual tab: Rich Text toggle works
- [ ] Visual tab: Collapse Empty Lines toggle works
- [ ] Visual tab: Text Color picker works, overlay text color changes
- [ ] General tab: Scroll Speed slider works, scroll speed changes in real-time
- [ ] General tab: Countdown toggle works
- [ ] General tab: Countdown Duration slider works, disabled when countdown is off
- [ ] All settings persist across app relaunch
- [ ] Settings sheet is 450x500, not resizable
- [ ] UI matches Apple HIG: proper spacing, GroupBox sections, light theme
- [ ] Close button (X) dismisses the sheet

---

## Round 3 — Integration + Polish (Sequential)

> **Prerequisite**: Round 2 (Agent C + D) must be complete.

### Agent E: Keyboard Shortcuts + Polish + Edge Cases

**Read first**: `doc/prd.md` (F5: Keyboard Shortcuts, full doc), `doc/ui-spec.md` (full doc), all source files

**Goal**: Add global hotkeys, polish the entire UI, handle edge cases, and verify screen-capture invisibility.

**Deliverables**:
- `OpenCue/Services/HotkeyManager.swift`:
  - Register global hotkey: Cmd+Shift+P → play/pause toggle (works even when app is not focused)
  - Use `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` or a lightweight SPM package like `HotKey`
  - Local shortcuts in main window: Space → play/pause, Cmd+Up → speed up, Cmd+Down → speed down, Cmd+R → reset scroll
- Polish sidebar:
  - Drag-to-reorder folders (update `sortOrder`)
  - Smooth selection animations
  - Folder icons (SF Symbol: `folder.fill`)
- Polish teleprompter overlay:
  - Smooth fade-in when appearing
  - Reading position indicator (subtle gradient fade at top/bottom edges of overlay)
  - "End" label or subtle indicator when scroll finishes
- Edge case handling:
  - **No notch detected**: Show an alert on launch explaining the app requires a MacBook with a notch. Provide a Quit button.
  - **Empty note**: Disable Play button, show "Note is empty" in overlay
  - **Very long text**: Ensure scroll completes without performance issues
  - **App backgrounded**: Teleprompter overlay stays visible (hidesOnDeactivate = false already set)
  - **Multiple displays**: Use the built-in display (the one with the notch), ignore external monitors
- App icon: Create a simple app icon or use an SF Symbol placeholder
- Menu bar: Add standard Edit menu (Copy, Paste, Select All — needed for the text editor)
- About window: Simple about panel with app name and version

**Checklist**:
- [ ] Cmd+Shift+P toggles play/pause globally (even when app is not focused)
- [ ] Space toggles play/pause when main window is focused
- [ ] Cmd+Up increases scroll speed by 1
- [ ] Cmd+Down decreases scroll speed by 1
- [ ] Cmd+R resets scroll to top
- [ ] Folders can be reordered by dragging
- [ ] Folder icons display correctly
- [ ] Teleprompter overlay fades in smoothly on launch
- [ ] Overlay has gradient fade at top/bottom edges for readability
- [ ] Alert shown on Macs without a notch
- [ ] Play button disabled when note is empty
- [ ] Long text scrolls without lag
- [ ] Overlay stays visible when app loses focus
- [ ] Copy/Paste works in the text editor
- [ ] App icon is present
- [ ] Test: overlay is invisible on QuickTime screen recording
- [ ] Test: overlay is invisible on Zoom screen share
- [ ] Test: overlay is invisible on Google Meet screen share
- [ ] Overall UI feels clean, polished, consistent with Apple design language

---

## Round 4 — Ship (Sequential)

> **Prerequisite**: Round 3 (Agent E) must be complete.

### Agent F: Code Signing + Notarization + DMG

**Read first**: `doc/prd.md` (Distribution section), Apple's notarization docs

**Goal**: Produce a signed, notarized DMG ready for distribution.

**Tasks**:
1. Configure Xcode project signing:
   - Team: Developer ID
   - Signing certificate: "Developer ID Application"
   - Hardened Runtime: enabled
   - Entitlements: only what's needed (likely none for MVP)
2. Archive the app via `xcodebuild archive`
3. Export with "Developer ID" method
4. Notarize via `xcrun notarytool submit`
5. Staple the ticket: `xcrun stapler staple`
6. Package into DMG (use `create-dmg` or `hdiutil`)
7. Test: download DMG on a clean Mac, open, drag to Applications, launch — no Gatekeeper warnings

**Checklist**:
- [ ] App is signed with Developer ID certificate
- [ ] Hardened Runtime is enabled
- [ ] App is notarized by Apple
- [ ] Notarization ticket is stapled to the app
- [ ] DMG is created with app + Applications shortcut
- [ ] App launches without Gatekeeper warnings on a clean Mac
- [ ] App icon appears correctly in DMG and Applications folder

---

## File Ownership Matrix

Prevents merge conflicts when agents work in parallel.

| File | Agent A | Agent B | Agent C | Agent D | Agent E |
|------|---------|---------|---------|---------|---------|
| `OpenCueApp.swift` | Creates | Updates (ModelContainer) | Updates (ScrollEngine env) | Updates (AppSettings env) | Final tweaks |
| `Models/Folder.swift` | | Creates | | | |
| `Models/Note.swift` | | Creates | | | |
| `Models/AppSettings.swift` | | | | Creates | |
| `Views/MainWindow/MainContentView.swift` | | Creates | | | Polishes |
| `Views/MainWindow/SidebarView.swift` | | Creates | | | Polishes (drag reorder) |
| `Views/MainWindow/EditorView.swift` | | Creates | | | Polishes |
| `Views/Teleprompter/TeleprompterWindow.swift` | Creates | | Updates | Updates (reads settings) | Polishes |
| `Views/Teleprompter/TeleprompterOverlay.swift` | Creates | | Updates (scroll) | Updates (reads settings) | Polishes |
| `Views/Teleprompter/CountdownView.swift` | | | Creates | | |
| `Views/Settings/SettingsView.swift` | | | | Creates | |
| `Views/Settings/VisualTab.swift` | | | | Creates | |
| `Views/Settings/GeneralTab.swift` | | | | Creates | |
| `Services/NotchDetector.swift` | Creates | | | | |
| `Services/ScrollEngine.swift` | | | Creates | | |
| `Services/HotkeyManager.swift` | | | | | Creates |
| `Utilities/Constants.swift` | Creates | | | | |

---

## Shared State Contracts

Agents must agree on these interfaces so their code connects cleanly.

### ScrollEngine (Agent C creates, others consume)

```swift
@Observable
class ScrollEngine {
    var state: ScrollState    // .idle, .countdown, .playing, .paused, .finished
    var offset: CGFloat       // current scroll Y offset
    func play()
    func pause()
    func reset()
    func setSpeed(_ speed: Double)
}
```

### AppSettings (Agent D creates, others consume)

```swift
@Observable
class AppSettings {
    // All @AppStorage properties
    var fontSize: Double      // 12-36, default 19
    var overlayWidth: Double  // 200-500, default 300
    var overlayHeight: Double // 80-300, default 130
    var opacity: Double       // 0.5-1.0, default 0.95
    var textAlignment: String // "left"/"center"/"right"/"justified", default "center"
    var scrollSpeed: Double   // 1-10, default 3
    var countdownEnabled: Bool // default true
    var countdownDuration: Int // 1-10, default 3
    // ... other properties
}
```

### Selected Note (Agent B establishes, others read)

```swift
// Shared via @Environment or @Binding
// The currently selected Note object (or nil)
var selectedNote: Note?
```

Agents C, D, E all read `selectedNote` to know what text to display/scroll. Agent B owns the selection logic.
