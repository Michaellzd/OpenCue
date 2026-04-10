# OpenCue - Data Model

## Persistence Strategy

- **Notes & Folders**: SwiftData (backed by SQLite, zero-config)
- **User Settings**: `@AppStorage` / `UserDefaults` (key-value pairs)

## SwiftData Models

### Folder

```swift
@Model
class Folder {
    var id: UUID
    var name: String
    var createdAt: Date
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade)
    var notes: [Note]
}
```

### Note

```swift
@Model
class Note {
    var id: UUID
    var title: String
    var body: String          // plain text content
    var createdAt: Date
    var updatedAt: Date
    
    var folder: Folder?
}
```

## UserDefaults Keys (AppSettings)

All keys are prefixed with `opencue.` to avoid collisions.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `opencue.fontSize` | Double | 19 | Teleprompter font size (pt) |
| `opencue.overlayWidth` | Double | 300 | Overlay width (px) |
| `opencue.overlayHeight` | Double | 130 | Overlay height (px) |
| `opencue.opacity` | Double | 0.95 | Overlay background opacity |
| `opencue.textAlignment` | String | "center" | left/center/right/justified |
| `opencue.textColor` | Data | black (encoded) | Encoded NSColor |
| `opencue.richTextEnabled` | Bool | true | Enable rich text rendering |
| `opencue.collapseEmptyLines` | Bool | false | Strip consecutive blank lines |
| `opencue.scrollSpeed` | Double | 3 | Scroll speed (1-10 scale) |
| `opencue.countdownEnabled` | Bool | true | Show countdown before scroll |
| `opencue.countdownDuration` | Int | 3 | Countdown seconds (1-10) |
| `opencue.lastOpenedNoteId` | String? | nil | UUID of last viewed note |
| `opencue.lastOpenedFolderId` | String? | nil | UUID of last viewed folder |

## Relationships

```
Folder 1 --- * Note
```

- Deleting a folder cascades to delete all its notes
- A note always belongs to exactly one folder
- Folders are ordered by `sortOrder` (user can reorder via drag)
- Notes within a folder are ordered by `updatedAt` descending (most recent first)
