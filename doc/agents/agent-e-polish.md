# Agent E: Keyboard Shortcuts + Polish + Edge Cases

## Who You Are

You are the **integration and polish** agent for **OpenCue**. All core features are built. Your job is to add keyboard shortcuts, handle edge cases, polish the UI to feel clean and professional, and verify the app works end-to-end.

You are working in **Round 3**, solo. All previous agents (A through D) have completed their work.

## Context

OpenCue is a macOS teleprompter app that sits in the MacBook notch, invisible to screen capture. At this point:
- Agent A built the notch overlay window (NSPanel, sharingType = .none)
- Agent B built folder/note management with SwiftData
- Agent C built the scroll engine with play/pause/countdown
- Agent D built the settings system (AppSettings + settings sheet)

Read the full spec:
- `doc/prd.md` — feature F5 (Keyboard Shortcuts), full requirements
- `doc/ui-spec.md` — all sections, focus on polish details
- `doc/agent-tasks.md` — your checklist and scope

## Existing Code

Before writing ANY code, read the ENTIRE codebase:

```
OpenCue/OpenCue/
├── OpenCueApp.swift
├── Models/
│   ├── Folder.swift
│   ├── Note.swift
│   └── AppSettings.swift
├── Views/
│   ├── MainWindow/
│   │   ├── MainContentView.swift
│   │   ├── SidebarView.swift
│   │   └── EditorView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── VisualTab.swift
│   │   └── GeneralTab.swift
│   └── Teleprompter/
│       ├── TeleprompterWindow.swift
│       ├── TeleprompterOverlay.swift
│       └── CountdownView.swift
├── Services/
│   ├── NotchDetector.swift
│   └── ScrollEngine.swift
├── Utilities/
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

Read ALL of these files before making any changes. Understand how data flows between components.

## What You Must Build

### 1. HotkeyManager.swift (NEW)

`OpenCue/OpenCue/Services/HotkeyManager.swift`

Register global keyboard shortcuts that work even when the app is NOT in focus.

**Global hotkeys (work system-wide):**

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+P | Toggle play/pause |

Use `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` for global hotkeys. Also register a local monitor with `NSEvent.addLocalMonitorForEvents` so the same shortcut works when the app IS focused.

```swift
class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let scrollEngine: ScrollEngine
    
    init(scrollEngine: ScrollEngine) {
        self.scrollEngine = scrollEngine
        setupMonitors()
    }
    
    private func setupMonitors() {
        // Global: works when app is NOT focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        // Local: works when app IS focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        switch (flags, event.keyCode) {
        case ([.command, .shift], 35): // Cmd+Shift+P (keyCode 35 = P)
            togglePlayPause()
        default:
            break
        }
    }
    
    func teardown() {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
    }
}
```

**Local shortcuts (only when main window is focused):**

Add these as SwiftUI `.keyboardShortcut()` modifiers or handle via the local event monitor:

| Shortcut | Action |
|----------|--------|
| Cmd+Up | Increase scroll speed by 1 |
| Cmd+Down | Decrease scroll speed by 1 |
| Cmd+R | Reset scroll to top |

For speed changes, clamp to 1-10 range. Update both `scrollEngine.speed` and `appSettings.scrollSpeed`.

**Note about Space key:** Do NOT use Space as a global play/pause shortcut — it conflicts with text editing in the EditorView. Only use Cmd+Shift+P as the play/pause toggle.

### 2. Sidebar Polish

Update `SidebarView.swift`:

**Drag-to-reorder folders:**
- Implement `.draggable` and `.dropDestination` (or `onMove`) on the folder list
- When reordered, update `sortOrder` values on all affected folders
- Notes within folders do NOT need reordering (they sort by updatedAt)

**Folder icons:**
- Each folder row: `Label(folder.name, systemImage: "folder.fill")`
- Each note row: `Label(note.title, systemImage: "doc.text")`

**Selection animation:**
- Ensure list selection has smooth default animation
- Use `.animation(.default, value: selectedNoteId)` if needed

### 3. Teleprompter Overlay Polish

Update `TeleprompterOverlay.swift`:

**Gradient fade edges:**
Add a gradient overlay at the top and bottom edges of the teleprompter for readability. Text fades out at the edges instead of being hard-clipped.

```swift
.overlay(
    VStack {
        LinearGradient(
            colors: [Color.white.opacity(settings.opacity), Color.white.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 20)
        Spacer()
        LinearGradient(
            colors: [Color.white.opacity(0), Color.white.opacity(settings.opacity)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 20)
    }
)
```

**Fade-in on launch:**
- When the teleprompter panel first appears, fade it in with `.opacity` animation over 0.3s

**Finished state indicator:**
- When scroll state is `.finished`, show a subtle "End" label centered in the overlay, small and gray
- Or show a thin colored line at the bottom

### 4. Edge Cases

**No notch detected:**
- On launch, if `NotchDetector.detect()` returns nil, show an alert:
  - Title: "Notch Required"
  - Message: "OpenCue requires a MacBook with a notch display. External monitors are not supported."
  - Button: "Quit" (terminates app) and "Continue Anyway" (for testing — hides the overlay)

**Empty note body:**
- Play button should already be disabled (Agent C did this)
- Double-check this works. If the body becomes empty mid-scroll, pause and reset.

**Very long text:**
- Test with 5000+ words to ensure smooth scrolling without memory/performance issues
- If `GeometryReader` for text height measurement causes issues with very long text, consider calculating text height mathematically using font metrics

**App loses focus:**
- Verify teleprompter overlay stays visible when the app is in background
- Verify `hidesOnDeactivate = false` is set (Agent A should have done this)

**Multiple displays:**
- If the user has external monitors, ensure the teleprompter appears on the built-in display (the one with the notch), not an external
- `NotchDetector` should specifically target the built-in screen

### 5. Menu Bar

Ensure the app has proper macOS menus:

**Edit menu** — critical for the text editor to support Copy/Paste/Select All:
```swift
// SwiftUI apps get Edit menu automatically, but verify it works
// If not, add via Commands:
.commands {
    // The default edit menu should handle Copy/Paste/Select All
    // Only add custom commands if needed
}
```

**App menu:**
- "About OpenCue" should show a simple about panel (use `.commands { CommandGroup(replacing: .appInfo) { ... } }`)
- Version: 1.0.0

### 6. App Icon

Create or add a simple app icon in `Assets.xcassets`:
- If you can generate one: a minimal teleprompter/cue icon (a scroll or play arrow in a rounded rect)
- If not: use a placeholder SF Symbol rendered as an icon, or leave a `// TODO: add app icon` with the AppIcon set empty

### 7. Integration Testing

After all changes, verify the full flow works end-to-end:

1. Launch app → main window appears, overlay appears in notch area
2. Create a folder → create a note → type/paste a long script
3. Open Settings → adjust font size, width, overlay opacity → confirm overlay updates live
4. Close Settings → hit Play → countdown appears → text scrolls
5. Cmd+Shift+P → pauses globally (even with another app focused)
6. Cmd+Shift+P → resumes
7. Text reaches end → stops automatically
8. Screen record with QuickTime → overlay is invisible
9. Quit and relaunch → data persists, last note is selected

## What You Must NOT Do

- Do NOT rewrite existing features that work correctly — only polish and fix
- Do NOT change data models (Folder, Note) — they're stable
- Do NOT change AppSettings keys or defaults — they're stable
- Do NOT change the NSPanel core configuration (sharingType, level) — it's correct
- Do NOT add new features beyond what's specified here

## Acceptance Checklist

### Keyboard Shortcuts
- [ ] Cmd+Shift+P toggles play/pause (works globally, even when app is not focused)
- [ ] Cmd+Up increases scroll speed by 1 (clamped at 10)
- [ ] Cmd+Down decreases scroll speed by 1 (clamped at 1)
- [ ] Cmd+R resets scroll to top
- [ ] Shortcuts don't conflict with text editing in EditorView

### Sidebar Polish
- [ ] Folders can be reordered by dragging
- [ ] Folder icons (folder.fill) display correctly
- [ ] Note icons (doc.text) display correctly
- [ ] Sidebar animations are smooth

### Teleprompter Polish
- [ ] Gradient fade at top and bottom edges of overlay
- [ ] Overlay fades in on launch (not a hard pop)
- [ ] "End" indicator shows when scroll finishes
- [ ] Smooth, consistent scroll with no visual artifacts

### Edge Cases
- [ ] Alert shown on Macs without a notch (or if notch detection fails)
- [ ] Play button disabled for empty notes
- [ ] Long text (5000+ words) scrolls without performance issues
- [ ] Overlay stays visible when app loses focus
- [ ] Overlay appears on built-in display, not external monitors

### Menu & Meta
- [ ] Copy/Paste/Select All work in the text editor
- [ ] About OpenCue panel shows app name and version
- [ ] App icon is present (even if placeholder)

### End-to-End
- [ ] Full workflow: create folder → note → edit → play → pause → resume → finish
- [ ] Settings changes apply in real-time during playback
- [ ] Data persists across relaunch
- [ ] Overlay invisible in QuickTime screen recording
- [ ] Overlay invisible on Zoom screen share (if testable)
