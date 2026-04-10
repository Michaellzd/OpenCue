# OpenCue - Implementation Plan

Ordered build phases. Each phase is independently testable. An LLM agent should complete one phase fully before moving to the next.

---

## Phase 1: Project Scaffold + Notch Window

**Goal**: Get a borderless, capture-invisible window showing static text in the notch area.

**Tasks**:
1. Create Xcode project (SwiftUI, macOS 14+ deployment target)
2. Implement `NotchDetector` - detect notch position via `NSScreen` APIs
3. Create `TeleprompterWindow` - `NSPanel` subclass with:
   - `sharingType = .none`
   - Borderless, always-on-top, non-activating
   - Positioned at notch coordinates
4. Display a hardcoded string in the overlay to verify positioning
5. Verify the window is invisible in a QuickTime screen recording

**Acceptance**: A floating text panel appears over the notch, does not appear in screen capture.

---

## Phase 2: Data Model + Content Management

**Goal**: Users can create folders and notes, edit note content.

**Tasks**:
1. Define SwiftData models (`Folder`, `Note`)
2. Set up `ModelContainer` in the app entry point
3. Build `SidebarView` with folder/note tree
4. Build `EditorView` with title + body editing
5. Wire up `NavigationSplitView` (sidebar + editor)
6. Implement CRUD: create/rename/delete folders and notes
7. Implement auto-save (debounced writes on text change)
8. Remember last-opened note on relaunch

**Acceptance**: User can create a folder, add notes, edit content, relaunch and see their data.

---

## Phase 3: Scroll Engine + Playback

**Goal**: Text scrolls in the teleprompter overlay, controlled by play/pause.

**Tasks**:
1. Implement `ScrollEngine` (ObservableObject with timer-based offset)
2. Wire `TeleprompterOverlay` to display the currently selected note's text
3. Animate text scrolling upward driven by `ScrollEngine.offset`
4. Add Play/Pause button to main window toolbar
5. Implement countdown overlay (3-2-1 before scroll starts)
6. Reset scroll position when switching notes

**Acceptance**: User selects a note, hits Play, sees countdown then smooth text scroll in the notch overlay.

---

## Phase 4: Settings UI

**Goal**: All appearance and scroll settings are configurable.

**Tasks**:
1. Create `AppSettings` class wrapping `@AppStorage` for all settings
2. Build Settings sheet with Visual and General tabs
3. Wire appearance settings to teleprompter overlay (font size, width, height, opacity, alignment, text color)
4. Wire scroll settings to `ScrollEngine` (speed)
5. Wire countdown settings (enable/disable, duration)
6. Wire formatting toggles (rich text, collapse empty lines)
7. Ensure all changes apply in real-time (no save button needed)

**Acceptance**: Changing any setting immediately updates the teleprompter overlay appearance/behavior.

---

## Phase 5: Keyboard Shortcuts + Polish

**Goal**: Global hotkeys work, UI is polished and clean.

**Tasks**:
1. Implement `HotkeyManager` for global shortcuts (Cmd+Shift+P for play/pause, etc.)
2. Add local keyboard shortcuts (Space for play/pause when main window focused)
3. Polish sidebar UI: drag-to-reorder folders, smooth animations
4. Add empty states (no folders, no notes selected)
5. Add app icon
6. Handle edge cases:
   - No notch detected (show alert explaining notch requirement)
   - Empty note (disable play button)
   - Very long text (ensure scroll completes smoothly)
7. Test with Zoom, Google Meet, and FaceTime screen sharing to confirm invisibility

**Acceptance**: App is usable end-to-end with keyboard shortcuts. Invisible on all tested screen sharing platforms.

---

## Phase 6: Distribution

**Goal**: Ship a notarized DMG.

**Tasks**:
1. Configure code signing (Developer ID)
2. Set up notarization workflow (Xcode or `xcrun notarytool`)
3. Create DMG with `create-dmg` or Xcode archive
4. Test installation on a clean Mac

**Acceptance**: DMG installs and runs without Gatekeeper warnings.

---

## Dependencies Between Phases

```
Phase 1 (Window) ─┐
                   ├── Phase 3 (Scroll) ── Phase 5 (Polish)
Phase 2 (Data)  ───┘                           │
                                                v
Phase 4 (Settings) ──────────────────── Phase 6 (Ship)
```

Phase 1 and Phase 2 can be built in parallel. Phase 3 requires both. Phase 4 can start after Phase 2 (settings UI doesn't need the overlay). Phase 5 requires everything. Phase 6 is last.
