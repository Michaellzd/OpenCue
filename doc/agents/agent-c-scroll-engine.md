# Agent C: Scroll Engine + Playback

## Who You Are

You are building the **scroll engine** and **playback controls** for **OpenCue**. You make the teleprompter overlay actually scroll text and add play/pause/countdown functionality.

You are working in **Round 2** alongside Agent D (who builds settings UI). You depend on Agent A's teleprompter window and Agent B's data model — both are already complete when you start.

## Context

OpenCue is a macOS teleprompter app. Agent A built the notch overlay window (borderless `NSPanel` with `sharingType = .none`). Agent B built the main window with folder/note management and a text editor. Your job: make the overlay show the selected note's text, scroll it smoothly, and give the user play/pause controls.

Read these docs:
- `doc/architecture.md` — ScrollEngine section, data flow
- `doc/prd.md` — feature F4 (Scroll & Playback)
- `doc/ui-spec.md` — teleprompter overlay states (idle, countdown, playing, finished)
- `doc/agents/agent-a-notch-window.md` — understand what Agent A built
- `doc/agents/agent-b-data-ui.md` — understand what Agent B built

## Existing Code You'll Work With

Before writing any code, READ these files to understand the current state:

- `OpenCue/OpenCue/OpenCueApp.swift` — App entry point with AppDelegate
- `OpenCue/OpenCue/Views/Teleprompter/TeleprompterWindow.swift` — NSPanel config
- `OpenCue/OpenCue/Views/Teleprompter/TeleprompterOverlay.swift` — Current placeholder view
- `OpenCue/OpenCue/Views/MainWindow/MainContentView.swift` — Main window root
- `OpenCue/OpenCue/Models/Note.swift` — Note model
- `OpenCue/OpenCue/Utilities/Constants.swift` — Default values

## What You Must Build

### File Structure

```
OpenCue/OpenCue/
├── Services/
│   └── ScrollEngine.swift          # NEW
├── Views/
│   └── Teleprompter/
│       ├── TeleprompterOverlay.swift  # UPDATE (replace hardcoded text)
│       └── CountdownView.swift        # NEW
```

You also update:
- `OpenCueApp.swift` — inject `ScrollEngine` as environment object
- `MainContentView.swift` — add Play/Pause toolbar button, wire to ScrollEngine

### 1. ScrollEngine.swift

The core state machine that drives scrolling.

```swift
import SwiftUI
import Combine

enum ScrollState {
    case idle        // Not scrolling, waiting for user action
    case countdown   // Showing 3-2-1 countdown
    case playing     // Actively scrolling text
    case paused      // Scroll paused mid-way
    case finished    // Text has scrolled to the end
}

@Observable
class ScrollEngine {
    var state: ScrollState = .idle
    var offset: CGFloat = 0           // Current scroll Y offset in points
    var currentCountdown: Int = 3     // Current countdown number being shown
    
    // Configuration (will be wired to AppSettings by Agent D)
    var speed: Double = 3             // 1-10 scale
    var countdownEnabled: Bool = true
    var countdownDuration: Int = 3
    
    // The text content to scroll (set when note selection changes)
    var textContent: String = ""
    var textHeight: CGFloat = 0       // Total height of rendered text
    var viewportHeight: CGFloat = 130 // Visible area height
    
    private var scrollTimer: Timer?
    private var countdownTimer: Timer?
    
    func play() { ... }
    func pause() { ... }
    func reset() { ... }
    func setSpeed(_ newSpeed: Double) { ... }
    
    // Called when text finishes scrolling
    private func checkFinished() { ... }
}
```

**Speed mapping:**
- The speed slider goes 1-10. Map this to pixels-per-tick:
- `pixelsPerTick = speed * 0.5` (so speed 1 = 0.5px/tick, speed 10 = 5px/tick)
- Timer fires at 60fps: `Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true)`
- Each tick: `offset += pixelsPerTick`

**State transitions:**
```
idle ──play()──> countdown ──timer──> playing ──pause()──> paused
  ^                                     │                    │
  │                                     └──checkFinished()──>finished
  │                                                          │
  └──────────────────────reset()─────────────────────────────┘
                         reset()◄────────paused
```

- `play()`: If idle → start countdown (or go straight to playing if countdown disabled). If paused → resume playing.
- `pause()`: If playing → paused. Stop scroll timer but keep offset.
- `reset()`: From any state → idle. Set offset = 0. Stop all timers.
- Countdown: Decrement `currentCountdown` every 1 second. When it reaches 0 → start playing.
- Finished: When `offset >= textHeight - viewportHeight` → stop timer, set state to `.finished`.

### 2. Update TeleprompterOverlay.swift

Replace the hardcoded placeholder with a live, scrolling view.

```swift
struct TeleprompterOverlay: View {
    @Environment(ScrollEngine.self) var scrollEngine
    
    var body: some View {
        ZStack {
            if scrollEngine.state == .countdown {
                CountdownView(number: scrollEngine.currentCountdown)
            } else {
                scrollingTextView
            }
        }
        .frame(width: 300, height: 130) // Will be dynamic via AppSettings later
        .background(Color.white.opacity(0.95))
        .clipped()
    }
    
    var scrollingTextView: some View {
        // The text, offset upward by scrollEngine.offset
        Text(scrollEngine.textContent)
            .font(.system(size: 19))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .offset(y: -scrollEngine.offset)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        scrollEngine.textHeight = geo.size.height
                    }
                }
            )
    }
}
```

**Key details:**
- Use `.offset(y: -scrollEngine.offset)` to shift text upward
- Use `GeometryReader` to measure the total text height and report it to `ScrollEngine`
- Clip the view so text doesn't overflow outside the overlay bounds
- When `state == .countdown`, show `CountdownView` instead of text
- When `state == .idle`, show text at offset 0 (static preview of first lines)
- When `state == .finished`, show text at final offset (last lines visible)

### 3. CountdownView.swift

A full-overlay countdown display.

```swift
struct CountdownView: View {
    let number: Int
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.black.opacity(0.8))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: number)
    }
}
```

- Large centered number
- Subtle scale + fade animation when number changes
- Fills the entire overlay area

### 4. Update MainContentView.swift — Toolbar

Add Play/Pause button to the existing toolbar. Read Agent B's `MainContentView.swift` first to understand the current toolbar setup.

Add these toolbar items (don't remove existing ones):

```swift
ToolbarItem(placement: .primaryAction) {
    Button(action: { togglePlayback() }) {
        Image(systemName: scrollEngine.state == .playing ? "pause.fill" : "play.fill")
            .foregroundColor(scrollEngine.state == .playing ? .blue : .primary)
    }
    .disabled(selectedNote == nil || selectedNote?.body.isEmpty == true)
    .help("Play/Pause teleprompter")
}
```

- Play button shows `play.fill` icon normally, `pause.fill` when playing
- Blue color when actively playing
- Disabled when no note is selected or note body is empty
- `togglePlayback()` logic:
  - If `.idle` or `.finished` → `scrollEngine.reset()` then `scrollEngine.play()`
  - If `.playing` → `scrollEngine.pause()`
  - If `.paused` → `scrollEngine.play()`

### 5. Update OpenCueApp.swift — Inject ScrollEngine

Add `ScrollEngine` as a shared object accessible to both windows:

```swift
@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var scrollEngine = ScrollEngine()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environment(scrollEngine)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 800, height: 550)
        .modelContainer(for: [Folder.self, Note.self])
    }
}
```

Also update the `AppDelegate.setupTeleprompterPanel()` to pass the `ScrollEngine` to the `TeleprompterOverlay`. This is tricky because the panel is created in AppKit-land. Options:
- Make `scrollEngine` a property on `AppDelegate`, then pass it to the hosting view
- Or use a shared singleton pattern
- Choose whichever integrates cleanly with the existing code

### 6. Wire Selected Note to ScrollEngine

When the user selects a different note in the sidebar:
- Set `scrollEngine.textContent = note.body`
- Call `scrollEngine.reset()` (scroll back to top)

When the user edits the note body while NOT playing:
- Update `scrollEngine.textContent` to the new body

Find where Agent B manages `selectedNote` in `MainContentView` and add this wiring. Use `.onChange(of: selectedNoteId)` to detect selection changes.

## What You Must NOT Do

- Do NOT modify the sidebar or editor views (except to add the play button to toolbar)
- Do NOT build settings UI — that's Agent D
- Do NOT add keyboard shortcuts — that's Agent E
- Do NOT change the NSPanel configuration (sharingType, level, etc.) — Agent A set those correctly
- Do NOT add `AppSettings` — that's Agent D. Use hardcoded defaults from `Constants.swift` for now.

## Acceptance Checklist

- [ ] `ScrollEngine` compiles with all state transitions working
- [ ] Teleprompter overlay shows the currently selected note's body text
- [ ] Switching notes updates the overlay text and resets scroll to top
- [ ] Tapping Play in toolbar:
  - [ ] Shows countdown (3, 2, 1) in the overlay
  - [ ] After countdown, text starts scrolling upward
- [ ] Scrolling is smooth (no visible jank or stuttering)
- [ ] Tapping Pause stops scrolling, text stays at current position
- [ ] Tapping Play again resumes scrolling from where it paused
- [ ] When text reaches the end, scrolling stops automatically (state = .finished)
- [ ] Tapping Play after finished resets to top and starts again
- [ ] Play button icon toggles between play.fill and pause.fill
- [ ] Play button turns blue when actively playing
- [ ] Play button is disabled when no note is selected
- [ ] Play button is disabled when the selected note's body is empty
- [ ] Countdown numbers animate smoothly (scale + fade)
- [ ] Editing note text while idle updates the overlay in real-time
- [ ] The overlay still passes the screen-capture invisibility test (you didn't break sharingType)

## Shared State Contract

You are CREATING `ScrollEngine`. Here's the interface other agents expect:

```swift
@Observable
class ScrollEngine {
    var state: ScrollState       // Current playback state
    var offset: CGFloat          // Current scroll Y offset
    var currentCountdown: Int    // Countdown number being displayed
    var speed: Double            // 1-10 scale (Agent D will wire to AppSettings)
    var countdownEnabled: Bool   // Agent D will wire to AppSettings
    var countdownDuration: Int   // Agent D will wire to AppSettings
    var textContent: String      // The text to scroll
    
    func play()
    func pause()
    func reset()
    func setSpeed(_ newSpeed: Double)
}
```

Agent D will later replace the hardcoded `speed`, `countdownEnabled`, and `countdownDuration` with values from `AppSettings`. Keep these as simple stored properties so Agent D can bind to them.
