# Agent B: Data Model + Content Management UI

## Who You Are

You are building the **main window** of **OpenCue** — the content management side where users create folders, manage notes (scripts), and edit text. You also define the data models and persistence layer.

You are working in **Round 1** alongside Agent A (who builds the teleprompter notch window). You do NOT depend on Agent A's work. Agent A does NOT depend on yours. You will never touch the same files.

## Context

OpenCue is a macOS teleprompter app. Users organize their scripts in folders (one per video/project), write or paste their content, then scroll it in a notch overlay during recording. Your job is the "content management" half — everything that happens in the main app window.

Read these docs for full context:
- `doc/data-model.md` — SwiftData models, relationships, UserDefaults keys
- `doc/architecture.md` — project structure, module responsibilities
- `doc/ui-spec.md` — main window section (Window 1), sidebar and editor specs

## Tech Stack

- Swift 5.9+
- SwiftUI (macOS 14+ / Sonoma deployment target)
- SwiftData for persistence
- No third-party dependencies

## What You Must Build

### File Structure

All your files go under the existing Xcode project (Agent A creates the project scaffold). If the project doesn't exist yet when you start, create these files in the expected paths — they'll be integrated later.

```
OpenCue/OpenCue/
├── Models/
│   ├── Folder.swift
│   └── Note.swift
├── Views/
│   └── MainWindow/
│       ├── MainContentView.swift
│       ├── SidebarView.swift
│       └── EditorView.swift
```

You also need to update:
- `OpenCueApp.swift` — add `ModelContainer`, set window size, use `MainContentView` as root

### 1. Folder.swift — SwiftData Model

```swift
import SwiftData
import Foundation

@Model
class Folder {
    var id: UUID = UUID()
    var name: String = "New Folder"
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    var notes: [Note] = []
    
    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
```

### 2. Note.swift — SwiftData Model

```swift
import SwiftData
import Foundation

@Model
class Note {
    var id: UUID = UUID()
    var title: String = "Untitled"
    var body: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var folder: Folder?
    
    init(title: String, folder: Folder) {
        self.id = UUID()
        self.title = title
        self.body = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folder = folder
    }
}
```

### 3. MainContentView.swift

The root view for the main window. Uses `NavigationSplitView` with two columns:

```
┌──────────────┬──────────────────────────────────┐
│  Sidebar     │  Editor                          │
│  (220px)     │  (fills remaining space)         │
│              │                                  │
│  Folders     │  Note title                      │
│  └ Notes     │  ──────────                      │
│              │  Note body text editor            │
│              │                                  │
│  + New Folder│                          words: N│
└──────────────┴──────────────────────────────────┘
```

- Use `NavigationSplitView` with `columnVisibility` set to show sidebar
- Sidebar width ~220px (use `.navigationSplitViewColumnWidth`)
- Track selection state: `@State var selectedNoteId: UUID?`
- Store `selectedNoteId` in `UserDefaults` (key: `opencue.lastOpenedNoteId`) so it persists across relaunch
- Toolbar items (right side): placeholder buttons for Settings (gear) and Play (play icon) — just the buttons, no functionality yet. Agent C and D will wire these.

### 4. SidebarView.swift

The left panel showing the folder/note tree.

**Structure:**
- A `List` with `selection` binding to `selectedNoteId`
- Each `Folder` is a `DisclosureGroup` (expandable)
- Inside each folder, each `Note` is a row showing just the title
- At the bottom: "+ New Folder" button

**CRUD Operations (all via context menu):**

On a **Folder**:
- **Add Note**: Creates a new note inside this folder with title "Untitled" and selects it
- **Rename**: Inline text field editing (use a `@State` bool to toggle between `Text` and `TextField`)
- **Delete**: Confirmation dialog, then delete (cascade deletes all notes)

On a **Note**:
- **Rename**: Same inline editing pattern
- **Delete**: Delete the note. If it was selected, clear selection.

**Sorting:**
- Folders ordered by `sortOrder` ascending
- Notes within a folder ordered by `updatedAt` descending (most recently edited first)

**Empty state:**
- When no folders exist, show centered text: "Create a folder to get started" with a "New Folder" button

**Query:**
```swift
@Query(sort: \Folder.sortOrder) private var folders: [Folder]
```

### 5. EditorView.swift

The right panel for editing the selected note.

**Layout (top to bottom):**
1. **Title field**: Large font (`.title2`), single-line `TextField`, editable. Bound to `note.title`.
2. **Divider**: A subtle `Divider()` line
3. **Body editor**: `TextEditor` that fills remaining space. Bound to `note.body`. System font, size 14 for editing.
4. **Bottom bar**: Small gray text showing word count: "N words" aligned to trailing edge

**Auto-save:**
- Do NOT save on every keystroke — that's too frequent
- Use a debounce pattern: when text changes, start a 500ms timer. If text changes again, restart the timer. When the timer fires, save.
- Implementation: use `.onChange(of:)` on `note.title` and `note.body` with a `Task` + `Task.sleep(for: .milliseconds(500))` pattern, cancelling previous tasks
- On save, update `note.updatedAt = Date()`
- SwiftData auto-persists on context save, so just modifying the `@Model` properties triggers save

**Empty state:**
- When no note is selected (`selectedNoteId == nil`), show centered gray text: "Select or create a note"

**Focus:**
- When a note is selected, auto-focus the body editor (not the title)

### 6. Update OpenCueApp.swift

Agent A creates the initial `OpenCueApp.swift`. You need to update it:

```swift
@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 800, height: 550)
        .modelContainer(for: [Folder.self, Note.self])
    }
}
```

Key additions:
- Replace placeholder `ContentView()` with `MainContentView()`
- Add `.modelContainer(for: [Folder.self, Note.self])`
- Set `.defaultSize` and `.frame(minWidth:minHeight:)`

**Important:** Do NOT remove or break Agent A's `AppDelegate` code for the teleprompter panel. Just add your changes alongside it. If Agent A hasn't run yet, include the `AppDelegate` adapter line but leave the class empty — Agent A will fill it in.

## Design Guidelines

- **Light theme**: Use system colors (`Color.primary`, `Color.secondary`, `Color(.systemBackground)`)
- **Apple style**: Look at Apple's Notes app or Reminders app for reference
- **Spacing**: Use 8pt increments. Generous padding.
- **Typography**: System font (SF Pro). Title: `.title2`. Body editor: `.body` (size ~14). Sidebar items: `.body`.
- **Icons**: SF Symbols — `folder.fill` for folders, `doc.text` for notes, `plus` for add buttons
- **Animations**: Use `.animation(.default)` for list changes. No flashy animations.
- **Selection highlight**: System default selection highlight (blue) in sidebar

## What You Must NOT Do

- Do NOT build the teleprompter overlay or notch window — that's Agent A
- Do NOT build the scroll engine or playback logic — that's Agent C
- Do NOT build the settings sheet — that's Agent D
- Do NOT build `AppSettings.swift` — that's Agent D
- Do NOT add any third-party dependencies
- Do NOT add keyboard shortcuts — that's Agent E
- Do NOT implement drag-to-reorder folders — that's Agent E (just sort by `sortOrder`)

## Acceptance Checklist

- [ ] App launches and shows the main window at 800x550
- [ ] Main window has a split view: sidebar on left (~220px), editor on right
- [ ] Window can be resized, minimum 600x400
- [ ] **Folders:**
  - [ ] User can create a new folder (appears in sidebar with name "New Folder")
  - [ ] User can rename a folder via context menu (inline editing)
  - [ ] User can delete a folder via context menu (shows confirmation)
  - [ ] Deleting a folder deletes all its notes
  - [ ] Folders are displayed in order of `sortOrder`
- [ ] **Notes:**
  - [ ] User can add a note inside a folder via context menu
  - [ ] New note appears with title "Untitled" and is auto-selected
  - [ ] User can rename a note via context menu
  - [ ] User can delete a note via context menu
  - [ ] Notes within a folder are ordered by most recently edited first
- [ ] **Editor:**
  - [ ] Selecting a note shows its title and body in the editor
  - [ ] Title is editable in a large text field
  - [ ] Body is editable in a text editor that fills the space
  - [ ] Changes auto-save after 500ms of inactivity
  - [ ] `updatedAt` is updated on save
  - [ ] Word count displays at bottom-right
  - [ ] Empty state shows "Select or create a note" when nothing is selected
- [ ] **Persistence:**
  - [ ] All data survives app relaunch
  - [ ] Last-opened note is restored on relaunch
- [ ] **Empty states:**
  - [ ] No folders: shows "Create a folder to get started" with button
  - [ ] No note selected: shows "Select or create a note"
- [ ] **Toolbar:**
  - [ ] Settings gear icon present (no action yet, just the button)
  - [ ] Play button present (no action yet, just the button)
- [ ] **Visual quality:**
  - [ ] Light theme, clean Apple-style aesthetics
  - [ ] Proper spacing and alignment
  - [ ] SF Symbol icons on folders and notes
  - [ ] No visual glitches or layout overflow

## Notes for Future Agents

After you finish:
- **Agent C** will wire the Play button to a `ScrollEngine` and make the teleprompter overlay display the selected note's text. They need access to `selectedNote` — expose it cleanly.
- **Agent D** will add the Settings gear button action (opens a sheet). They need to add `.sheet` presentation to `MainContentView`.
- **Agent E** will add drag-to-reorder for folders and overall polish.

Make the selected note easily accessible. A good pattern: compute it from `selectedNoteId` using a SwiftData `@Query` or `modelContext.fetch`, and pass it down as a binding or environment value. Agent C needs to read `selectedNote.body` from the teleprompter overlay.
