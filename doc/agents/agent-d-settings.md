# Agent D: Settings UI + AppSettings

## Who You Are

You are building the **settings system** for **OpenCue** — the `AppSettings` model that stores all user preferences, the settings sheet UI with Visual and General tabs, and the wiring that makes settings changes apply to the teleprompter overlay in real-time.

You are working in **Round 2** alongside Agent C (who builds the scroll engine). You depend on Agent A's teleprompter window and Agent B's main window — both are already complete when you start.

## Context

OpenCue is a macOS teleprompter app. Agent A built the notch overlay window. Agent B built the content management UI. Agent C is simultaneously building the scroll engine. Your job: create all the user-configurable settings and wire them to the UI.

Read these docs:
- `doc/data-model.md` — UserDefaults keys section (all setting keys, types, defaults)
- `doc/prd.md` — feature F3 (Appearance Settings), F4 (Scroll & Playback settings)
- `doc/ui-spec.md` — Settings Sheet section (Visual tab, General tab wireframes)
- `doc/agents/agent-a-notch-window.md` — understand the overlay window
- `doc/agents/agent-b-data-ui.md` — understand the main window structure

## Existing Code You'll Work With

Before writing any code, READ these files:

- `OpenCue/OpenCue/OpenCueApp.swift` — App entry point
- `OpenCue/OpenCue/Views/MainWindow/MainContentView.swift` — Where to add sheet presentation
- `OpenCue/OpenCue/Views/Teleprompter/TeleprompterOverlay.swift` — Where settings are consumed
- `OpenCue/OpenCue/Views/Teleprompter/TeleprompterWindow.swift` — Panel sizing
- `OpenCue/OpenCue/Utilities/Constants.swift` — Current defaults
- `OpenCue/OpenCue/Services/ScrollEngine.swift` — If Agent C has created it, check the speed/countdown properties

## What You Must Build

### File Structure

```
OpenCue/OpenCue/
├── Models/
│   └── AppSettings.swift          # NEW
├── Views/
│   └── Settings/
│       ├── SettingsView.swift     # NEW
│       ├── VisualTab.swift        # NEW
│       └── GeneralTab.swift       # NEW
```

You also update:
- `OpenCueApp.swift` — inject AppSettings
- `MainContentView.swift` — add settings sheet presentation
- `TeleprompterOverlay.swift` — read AppSettings for font, color, alignment
- `TeleprompterWindow.swift` — read AppSettings for width, height, opacity, reposition/resize dynamically

### 1. AppSettings.swift

Central settings store using `@AppStorage` (UserDefaults).

```swift
import SwiftUI

@Observable
class AppSettings {
    // --- Appearance ---
    @AppStorage("opencue.fontSize") var fontSize: Double = 19
    @AppStorage("opencue.overlayWidth") var overlayWidth: Double = 300
    @AppStorage("opencue.overlayHeight") var overlayHeight: Double = 130
    @AppStorage("opencue.opacity") var opacity: Double = 0.95
    @AppStorage("opencue.textAlignment") var textAlignment: String = "center"
    @AppStorage("opencue.richTextEnabled") var richTextEnabled: Bool = true
    @AppStorage("opencue.collapseEmptyLines") var collapseEmptyLines: Bool = false
    @AppStorage("opencue.textColorData") var textColorData: Data = {
        // Encode default black color
        let color = NSColor.black
        return (try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)) ?? Data()
    }()
    
    // --- Scroll ---
    @AppStorage("opencue.scrollSpeed") var scrollSpeed: Double = 3
    @AppStorage("opencue.countdownEnabled") var countdownEnabled: Bool = true
    @AppStorage("opencue.countdownDuration") var countdownDuration: Int = 3
    
    // --- Computed helpers ---
    var textColor: Color {
        get {
            guard let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: textColorData) else {
                return .black
            }
            return Color(nsColor)
        }
        set {
            let nsColor = NSColor(newValue)
            textColorData = (try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: true)) ?? Data()
        }
    }
    
    var swiftUITextAlignment: TextAlignment {
        switch textAlignment {
        case "left": return .leading
        case "right": return .trailing
        case "center": return .center
        default: return .center
        }
    }
    
    var nsTextAlignment: NSTextAlignment {
        switch textAlignment {
        case "left": return .left
        case "right": return .right
        case "justified": return .justified
        default: return .center
        }
    }
}
```

**Important note about `@Observable` + `@AppStorage`:** The `@Observable` macro and `@AppStorage` property wrapper may not work together directly. If you encounter issues, use a pattern like this instead:
- Store values in `UserDefaults` manually
- Use `@Published` or observation-compatible properties
- Sync with UserDefaults in `didSet`

Choose whichever pattern compiles cleanly on macOS 14 + Swift 5.9. The key requirement is: other views can observe changes reactively, and values persist in UserDefaults.

### 2. SettingsView.swift

The container for the settings sheet.

```swift
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .visual
    @Environment(\.dismiss) private var dismiss
    
    enum SettingsTab: String, CaseIterable {
        case visual = "Visual"
        case general = "General"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Tab content
            ScrollView {
                switch selectedTab {
                case .visual:
                    VisualTab()
                case .general:
                    GeneralTab()
                }
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
}
```

### 3. VisualTab.swift

Appearance and formatting controls.

**Appearance section (GroupBox):**
- **Font Size**: `Slider(value:in:step:)` range 12...36, step 1. Label: "Font Size", value label: "\(Int(fontSize))"
- **Width**: Slider 200...500, step 10. Value label: "\(Int(width))px"
- **Height**: Slider 80...300, step 10. Value label: "\(Int(height))px"
- **Opacity**: Slider 50...100 (display as %), map to 0.5...1.0 internally. Value label: "\(Int(opacity*100))%"
- **Text Alignment**: Segmented `Picker` with options: Left, Center, Right, Justified

**Formatting section (GroupBox):**
- **Enable Rich Text Formatting**: `Toggle` (checkbox style on macOS)
- **Collapse Empty Lines**: `Toggle`
- **Text Color**: `ColorPicker`

**Layout pattern for each slider row:**
```swift
HStack {
    Text("Font Size")
    Spacer()
    Text("\(Int(settings.fontSize))")
        .foregroundColor(.secondary)
        .monospacedDigit()
}
Slider(value: $settings.fontSize, in: 12...36, step: 1)
```

**GroupBox styling:**
```swift
GroupBox {
    VStack(alignment: .leading, spacing: 12) {
        // controls here
    }
    .padding(8)
} label: {
    Label("Appearance", systemImage: "paintbrush.fill")
        .font(.headline)
}
```

### 4. GeneralTab.swift

Scroll and countdown controls.

**Scroll section (GroupBox):**
- **Scroll Speed**: Slider 1...10, step 1. Value label: "\(Int(speed))"

**Countdown section (GroupBox):**
- **Countdown Before Start**: Toggle (checkbox)
- **Countdown Duration**: Slider 1...10, step 1. Value label: "\(Int(duration))s". **Disabled** when countdown toggle is off.

### 5. Wire Settings to the Teleprompter Overlay

Update `TeleprompterOverlay.swift` to read from `AppSettings`:

```swift
struct TeleprompterOverlay: View {
    @Environment(AppSettings.self) var settings
    
    // Replace hardcoded values:
    // .font(.system(size: 19))        → .font(.system(size: settings.fontSize))
    // .foregroundColor(.black)         → .foregroundColor(settings.textColor)
    // .multilineTextAlignment(.center) → .multilineTextAlignment(settings.swiftUITextAlignment)
    // .frame(width: 300, height: 130)  → .frame(width: settings.overlayWidth, height: settings.overlayHeight)
    // .opacity(0.95)                   → .opacity(settings.opacity)
}
```

**Collapse empty lines:** If `settings.collapseEmptyLines` is true, preprocess the text to replace multiple consecutive newlines with a single newline.

### 6. Wire Settings to TeleprompterWindow (Panel Resizing)

When width, height, or opacity change, the `NSPanel` needs to resize/reposition. This is trickier because the panel is AppKit-managed.

**Approach:** Observe `AppSettings` changes in the `AppDelegate` and update the panel frame:

```swift
// In AppDelegate, observe settings changes
func observeSettings(_ settings: AppSettings) {
    // Use Combine or withObservationTracking to detect changes
    // When overlayWidth or overlayHeight changes:
    //   1. Compute new frame from NotchDetector + new size
    //   2. panel.setFrame(newFrame, display: true, animate: false)
    // When opacity changes:
    //   panel.backgroundColor = NSColor.white.withAlphaComponent(settings.opacity)
}
```

### 7. Wire Settings to ScrollEngine

If Agent C has created `ScrollEngine`, wire:
- `settings.scrollSpeed` → `scrollEngine.speed`
- `settings.countdownEnabled` → `scrollEngine.countdownEnabled`
- `settings.countdownDuration` → `scrollEngine.countdownDuration`

Use `.onChange(of:)` or direct binding. If Agent C hasn't finished yet, add a `// TODO: wire to ScrollEngine` comment and document what needs connecting.

### 8. Add Settings Sheet to MainContentView

Update `MainContentView.swift`:

```swift
@State private var showSettings = false

// In toolbar, wire the existing gear button:
ToolbarItem {
    Button(action: { showSettings = true }) {
        Image(systemName: "gearshape")
    }
}

// Add sheet modifier:
.sheet(isPresented: $showSettings) {
    SettingsView()
        .environment(settings)
}
```

### 9. Inject AppSettings in OpenCueApp.swift

```swift
@State private var appSettings = AppSettings()

// Add .environment(appSettings) to both the main window and teleprompter overlay
```

## What You Must NOT Do

- Do NOT modify the sidebar, editor, or folder/note logic — that's Agent B
- Do NOT modify ScrollEngine logic (play/pause/reset) — that's Agent C. Only wire settings TO it.
- Do NOT add keyboard shortcuts — that's Agent E
- Do NOT change NSPanel properties unrelated to settings (sharingType, level, etc.)

## Acceptance Checklist

- [ ] `AppSettings` compiles and stores all settings in UserDefaults
- [ ] All settings persist across app relaunch
- [ ] **Settings sheet:**
  - [ ] Gear icon in toolbar opens the settings sheet
  - [ ] Sheet is 450x500 and not resizable
  - [ ] "Settings" title and X close button at top
  - [ ] Segmented picker switches between Visual and General tabs
  - [ ] X button dismisses the sheet
- [ ] **Visual tab:**
  - [ ] Font Size slider (12-36) updates overlay font size in real-time
  - [ ] Width slider (200-500) resizes overlay in real-time
  - [ ] Height slider (80-300) resizes overlay in real-time
  - [ ] Opacity slider (50-100%) changes overlay background opacity in real-time
  - [ ] Text Alignment picker (Left/Center/Right/Justified) changes overlay alignment
  - [ ] Rich Text Formatting toggle works
  - [ ] Collapse Empty Lines toggle works (strips consecutive blank lines in overlay)
  - [ ] Text Color picker changes overlay text color in real-time
- [ ] **General tab:**
  - [ ] Scroll Speed slider (1-10) displays current value
  - [ ] Countdown Before Start toggle works
  - [ ] Countdown Duration slider (1-10) displays "Ns"
  - [ ] Duration slider is disabled when countdown is toggled off
- [ ] **Wiring:**
  - [ ] Overlay font size reacts to settings change immediately
  - [ ] Overlay dimensions react to width/height change immediately
  - [ ] Overlay repositions correctly when width changes (stays centered on notch)
  - [ ] Overlay background opacity reacts to settings change immediately
  - [ ] Scroll speed change takes effect on next play (or immediately if playing)
- [ ] **UI quality:**
  - [ ] Light theme, clean Apple-style
  - [ ] GroupBox sections with proper labels and icons
  - [ ] Slider rows show current value on the right
  - [ ] Proper spacing between controls (12-16pt)
  - [ ] No layout overflow or clipping

## Shared State Contract

You are CREATING `AppSettings`. Here's what other agents expect:

```swift
@Observable
class AppSettings {
    var fontSize: Double         // 12-36, default 19
    var overlayWidth: Double     // 200-500, default 300
    var overlayHeight: Double    // 80-300, default 130
    var opacity: Double          // 0.5-1.0, default 0.95
    var textAlignment: String    // "left"/"center"/"right"/"justified"
    var textColor: Color         // computed from encoded NSColor data
    var richTextEnabled: Bool    // default true
    var collapseEmptyLines: Bool // default false
    var scrollSpeed: Double      // 1-10, default 3
    var countdownEnabled: Bool   // default true
    var countdownDuration: Int   // 1-10, default 3
}
```

Agent C's `ScrollEngine` has `speed`, `countdownEnabled`, and `countdownDuration` as stored properties. You wire AppSettings to those properties using `.onChange` or direct binding.

Agent E will later read AppSettings but won't modify the model — your implementation is the final version.
