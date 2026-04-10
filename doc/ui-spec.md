# OpenCue - UI Specification

## Design Language

- **Theme**: Light mode, Apple HIG-aligned
- **Colors**: System defaults (`Color.primary`, `Color.secondary`, `Color.accentColor` = system blue)
- **Typography**: SF Pro (system font), no custom fonts
- **Spacing**: 8pt grid system
- **Corner radius**: System default (10-12pt for cards/panels)
- **Visual style**: Clean, minimal, generous whitespace. Similar to Apple's Notes or Reminders app.

---

## Window 1: Main Window

**Size**: 800x550 default, min 600x400, resizable  
**Title bar**: Standard macOS traffic lights + app title "OpenCue"

### Layout: NavigationSplitView

```
┌─────────────────────────────────────────────────┐
│  ● ● ●   OpenCue                    ⚙  ▶ Play  │  <- Toolbar
├──────────────┬──────────────────────────────────┤
│  Folders     │                                  │
│  ┌────────┐  │   Note Title (editable)          │
│  │ 📁 V1  │  │   ─────────────────────          │
│  │  └ Sc1  │  │                                  │
│  │  └ Sc2  │  │   Script body text here...       │
│  │ 📁 V2  │  │   User types or pastes their     │
│  │  └ Sc3  │  │   teleprompter content.          │
│  └────────┘  │                                  │
│              │                                  │
│  + New Folder│                                  │
├──────────────┴──────────────────────────────────┤
│                                          status │
└─────────────────────────────────────────────────┘
```

### Sidebar (Left Panel, ~220px)

- **Folder list**: Each folder is an expandable disclosure group
- **Note list**: Notes nested under their folder, showing title only
- **Add button**: "+ New Folder" at bottom of sidebar
- **Context menus**:
  - Folder: Rename, Add Note, Delete
  - Note: Rename, Move to Folder, Delete
- **Selection**: Highlighted note loads in editor pane
- **Empty state**: "Create a folder to get started" with a button

### Editor (Right Panel)

- **Title field**: Large, editable text field at top (auto-saves)
- **Body editor**: Full-height `TextEditor`, plain text, monospace-optional
- **Auto-save**: Changes saved 500ms after user stops typing (debounced)
- **Empty state**: "Select or create a note" centered message
- **Character/word count**: Small label at bottom-right of editor

### Toolbar

- **Left**: Standard window controls (handled by macOS)
- **Right**:
  - Settings gear icon -> opens Settings sheet
  - Play button (▶ / ⏸ toggle) -> starts/stops teleprompter scroll
  - The Play button is prominent (filled blue when active)

---

## Window 2: Teleprompter Overlay

**Type**: `NSPanel`, borderless, always-on-top, capture-invisible  
**Position**: Anchored to notch, extends downward  
**Background**: Semi-transparent white (controlled by opacity setting)

### Layout

```
     ┌─── Notch ───┐
     │              │
┌────┴──────────────┴────┐
│                        │
│   Scrolling text       │  <- Extends below notch
│   content here...      │
│                        │
└────────────────────────┘
```

### States

**Idle** (not playing):
- Shows first few lines of the selected note
- Static, no scrolling
- Slightly dimmed to indicate paused state

**Countdown**:
- Large centered number (3... 2... 1...)
- Fills the overlay area
- Each number fades/scales in with subtle animation

**Playing**:
- Text scrolls upward at configured speed
- Smooth animation (60fps via `CADisplayLink` or `TimelineView`)
- Current reading line is at the top of the visible area

**Finished**:
- Scroll stops at end of text
- Brief visual indicator (subtle flash or "End" label)

---

## Settings Sheet

**Presentation**: `.sheet` modal from main window  
**Size**: 450x500, not resizable  
**Layout**: Two tabs (Visual / General) via segmented control at top

### Visual Tab

```
┌──────────────────────────────────────┐
│  Settings                        ✕   │
│       [ Visual ]  [ General ]        │
│                                      │
│  ┌ Appearance ─────────────────────┐ │
│  │ Font Size              ●── 19   │ │
│  │ Width              ●──── 300px  │ │
│  │ Height          ●────── 130px   │ │
│  │ Opacity                ●── 95%  │ │
│  │ Text Alignment                  │ │
│  │ [Left][Center][Right][Justify]  │ │
│  └─────────────────────────────────┘ │
│                                      │
│  ┌ Formatting ─────────────────────┐ │
│  │ ☑ Enable Rich Text Formatting  │ │
│  │ ☐ Collapse Empty Lines         │ │
│  │ Text Color    [■ Black ▾]      │ │
│  └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### General Tab

```
┌──────────────────────────────────────┐
│  Settings                        ✕   │
│       [ Visual ]  [ General ]        │
│                                      │
│  ┌ Scroll ─────────────────────────┐ │
│  │ Scroll Speed           ●── 3   │ │
│  └─────────────────────────────────┘ │
│                                      │
│  ┌ Countdown ──────────────────────┐ │
│  │ ☑ Countdown Before Start       │ │
│  │ Countdown Duration     ●── 3s  │ │
│  └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Control Styling

- **Sliders**: Standard SwiftUI `Slider` with min/max labels
- **Toggles**: Standard SwiftUI `Toggle` (checkbox style on macOS)
- **Segmented control**: Standard `Picker` with `.segmented` style
- **Color picker**: `ColorPicker` (system color panel)
- **Sections**: Grouped with `GroupBox` or similar card-style containers with light gray background
