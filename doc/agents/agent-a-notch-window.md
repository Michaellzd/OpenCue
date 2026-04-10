# Agent A: Project Scaffold + Notch Teleprompter Window

## Who You Are

You are building the foundation of **OpenCue**, a macOS teleprompter app that lives in the MacBook notch. Your job is to create the Xcode project from scratch and get a floating, borderless, screen-capture-invisible panel showing text over the notch.

You are working in **Round 1** alongside Agent B (who builds the data model and main window UI). You do NOT depend on Agent B's work. Agent B does NOT depend on yours. You will never touch the same files.

## Context

OpenCue is a native macOS teleprompter. The key technical trick: the teleprompter window uses `NSWindow.sharingType = .none`, which makes it invisible to Zoom, Meet, Teams, QuickTime, and all screen capture APIs. The window sits right over the Mac's notch — using dead screen space.

Read these docs for full context:
- `doc/architecture.md` — system design, module responsibilities, project structure
- `doc/ui-spec.md` — teleprompter overlay section (Window 2)
- `doc/prd.md` — feature F1 (Notch Teleprompter Overlay)

## Tech Stack

- Swift 5.9+
- SwiftUI (macOS 14+ / Sonoma deployment target)
- Xcode 15+
- No third-party dependencies for this phase

## What You Must Build

### 1. Xcode Project

Create a new SwiftUI macOS app project at the repo root:

```
OpenCue/
├── OpenCue.xcodeproj
└── OpenCue/
    ├── OpenCueApp.swift
    ├── Services/
    │   └── NotchDetector.swift
    ├── Views/
    │   └── Teleprompter/
    │       ├── TeleprompterWindow.swift
    │       └── TeleprompterOverlay.swift
    ├── Utilities/
    │   └── Constants.swift
    └── Resources/
        └── Assets.xcassets
```

- Deployment target: macOS 14.0
- Bundle identifier: `com.opencue.app`
- Product name: OpenCue

### 2. OpenCueApp.swift

App entry point. Responsibilities:
- Declare a `WindowGroup` for the main window (just a placeholder view for now — Agent B builds the real content)
- Programmatically create and show the teleprompter panel on launch
- The teleprompter panel is NOT a `WindowGroup` — it's an `NSPanel` created and managed in code via `NSApplication` lifecycle (use `.onAppear` or an `AppDelegate` adapter)

```swift
@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView() // placeholder, Agent B replaces this
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var teleprompterPanel: NSPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupTeleprompterPanel()
    }
    
    func setupTeleprompterPanel() {
        // Create and configure the NSPanel here
    }
}
```

### 3. NotchDetector.swift

Detect the notch position on the current Mac's built-in display.

```swift
struct NotchGeometry {
    let x: CGFloat        // left edge of notch
    let y: CGFloat        // top of screen (where notch starts)
    let width: CGFloat    // notch width
    let screenWidth: CGFloat
}

class NotchDetector {
    static func detect() -> NotchGeometry?
    // Returns nil if no notch is found
}
```

**How to detect the notch:**
- On macOS 14+, use `NSScreen.main?.auxiliaryTopLeftArea` and `auxiliaryTopRightArea`. The gap between these two rects IS the notch.
- If those APIs aren't available, fall back to `NSScreen.main?.safeAreaInsets.top`. If it's > 0, there's a notch. Notch width is approximately 180-200px on 14" and 16" MacBooks.
- The notch is always on the built-in display. Use `NSScreen.screens` to find the built-in screen (it has `localizedName` containing "Built-in" or check `CGDisplayIsBuiltin`).

### 4. TeleprompterWindow.swift

Configure an `NSPanel` with these exact properties:

```swift
let panel = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: Constants.defaultOverlayWidth, height: Constants.defaultOverlayHeight),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)

// CRITICAL: This makes it invisible to screen capture
panel.sharingType = .none

// Always on top
panel.level = .statusBar + 1

// Don't steal focus
panel.isMovable = false
panel.hidesOnDeactivate = false
panel.canBecomeKey = false

// Click-through (don't interfere with other apps)
panel.ignoresMouseEvents = true

// Don't show in Mission Control / Dock / Cmd+Tab
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

// Semi-transparent background
panel.backgroundColor = NSColor.white.withAlphaComponent(0.95)
panel.isOpaque = false
panel.hasShadow = false
```

**Positioning:**
- The panel should be centered horizontally on the notch
- Its top edge should be at the bottom of the notch (the panel extends DOWNWARD from the notch)
- Use `NotchDetector` to compute: `x = notch.x + (notch.width - panelWidth) / 2`, `y = screen.frame.maxY - notch area height - panelHeight`
- The exact Y positioning needs care — the notch occupies the top portion of the menu bar. The panel should sit just below the notch, overlapping the area right under it.

**Host the SwiftUI view:**
```swift
let hostingView = NSHostingView(rootView: TeleprompterOverlay())
panel.contentView = hostingView
```

### 5. TeleprompterOverlay.swift

Simple SwiftUI view for now:

```swift
struct TeleprompterOverlay: View {
    var body: some View {
        ScrollView {
            Text("This is a test teleprompter text. OpenCue displays your script right here in the notch area. This text will eventually scroll automatically.")
                .font(.system(size: 19))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(12)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 300, height: 130)
        .background(Color.white.opacity(0.95))
    }
}
```

This is a placeholder. Agent C will later replace the hardcoded text with live note content and add scrolling.

### 6. Constants.swift

```swift
enum Constants {
    static let defaultFontSize: Double = 19
    static let defaultOverlayWidth: Double = 300
    static let defaultOverlayHeight: Double = 130
    static let defaultOpacity: Double = 0.95
    static let defaultScrollSpeed: Double = 3
    static let defaultCountdownDuration: Int = 3
}
```

## What You Must NOT Do

- Do NOT build the main window content (sidebar, editor) — that's Agent B
- Do NOT build the scroll engine or playback logic — that's Agent C
- Do NOT build settings UI — that's Agent D
- Do NOT add any third-party dependencies
- Do NOT add SwiftData or any models

## Acceptance Checklist

Test each item before considering your work complete:

- [ ] Xcode project compiles and runs without errors on macOS 14+
- [ ] On launch, a floating panel appears near the top of the screen in the notch area
- [ ] The panel displays readable text (the hardcoded placeholder)
- [ ] The panel has NO title bar, NO traffic lights, NO border, NO shadow
- [ ] The panel stays on top of ALL other windows (including fullscreen apps if possible)
- [ ] The panel does NOT appear in Mission Control
- [ ] The panel does NOT show in the Dock or Cmd+Tab switcher
- [ ] The panel does NOT steal focus — clicking elsewhere keeps the other app focused
- [ ] The panel is click-through — mouse events pass to windows behind it
- [ ] **CRITICAL**: Open QuickTime Player → New Screen Recording → Record. The panel must NOT appear in the recording. This verifies `sharingType = .none`.
- [ ] `NotchDetector` returns valid geometry on a MacBook with a notch
- [ ] `NotchDetector` returns nil on a Mac without a notch (if you can test this)
- [ ] The main window shows (even if it's just a placeholder ContentView)

## Notes for Future Agents

After you finish, these agents will build on your work:
- **Agent B** will replace the placeholder `ContentView()` with the real main window UI
- **Agent C** will update `TeleprompterOverlay` to show live note content and add scrolling
- **Agent D** will make the overlay read from `AppSettings` for dynamic sizing/styling
- **Agent E** will add polish (fade animations, gradient edges)

Keep your code clean and well-structured so they can extend it easily. Use clear, descriptive variable names. Add brief comments only where the intent isn't obvious (especially around the NSPanel configuration — explain WHY each property is set).
