import AppKit
import SwiftUI

@MainActor
final class TeleprompterWindowController: NSObject {
    private(set) var panel: NSPanel?
    private weak var settings: AppSettings?
    private weak var scrollEngine: ScrollEngine?

    /// Create the teleprompter panel positioned over the notch.
    func setup(scrollEngine: ScrollEngine, settings: AppSettings) {
        self.settings = settings
        self.scrollEngine = scrollEngine

        let panelWidth = settings.overlayWidthCGFloat
        let panelHeight = settings.overlayHeightCGFloat

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // CRITICAL — invisible to screen capture (Zoom, Meet, QuickTime, etc.)
        panel.sharingType = .none

        // Always on top of every other window
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)

        // Don't steal focus or interfere with other apps
        panel.isMovable = false
        panel.hidesOnDeactivate = false

        // Mouse interaction is enabled only while the teleprompter is visible.
        panel.ignoresMouseEvents = true

        // Don't appear in Mission Control, Dock, or Cmd+Tab
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Transparent / no chrome
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        // Host the SwiftUI overlay inside the panel
        let hostingView = NSHostingView(
            rootView: TeleprompterOverlay()
                .environment(settings)
                .environment(scrollEngine)
        )
        panel.contentView = hostingView

        // Position over the notch
        positionPanel(panel, width: panelWidth, height: panelHeight)

        panel.orderOut(nil)
        self.panel = panel
        observeSettings()
        observeScrollEngineState()
        applyVisibility(for: scrollEngine.state)
    }

    /// Position the panel centered on the notch, extending downward.
    private func positionPanel(_ panel: NSPanel, width: CGFloat, height: CGFloat) {
        panel.setFrame(frameForPanel(width: width, height: height), display: false)
    }

    private func observeSettings() {
        NotificationCenter.default.removeObserver(self, name: .appSettingsDidChange, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsDidChange(_:)),
            name: .appSettingsDidChange,
            object: settings
        )
    }

    private func observeScrollEngineState() {
        NotificationCenter.default.removeObserver(self, name: .scrollEngineStateDidChange, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScrollEngineStateDidChange(_:)),
            name: .scrollEngineStateDidChange,
            object: scrollEngine
        )
    }

    @objc
    private func handleSettingsDidChange(_ notification: Notification) {
        applySettings()
    }

    @objc
    private func handleScrollEngineStateDidChange(_ notification: Notification) {
        guard let scrollEngine else { return }
        applyVisibility(for: scrollEngine.state)
    }

    private func applySettings() {
        guard let panel, let settings else { return }

        let newFrame = frameForPanel(
            width: settings.overlayWidthCGFloat,
            height: settings.overlayHeightCGFloat
        )
        panel.setFrame(newFrame, display: true, animate: false)
    }

    private func applyVisibility(for state: ScrollState) {
        guard let panel else { return }

        if shouldShowPanel(for: state) {
            applySettings()
            panel.ignoresMouseEvents = false
            panel.orderFrontRegardless()
        } else {
            panel.ignoresMouseEvents = true
            panel.orderOut(nil)
        }
    }

    private func shouldShowPanel(for state: ScrollState) -> Bool {
        switch state {
        case .idle:
            return false
        case .playing, .paused, .finished:
            return true
        }
    }

    private func frameForPanel(width: CGFloat, height: CGFloat) -> NSRect {
        if let notch = NotchDetector.detect() {
            let x = notch.centerX - width / 2
            let y = notch.bottomY - height
            return NSRect(x: x, y: y, width: width, height: height)
        }

        if let screen = NSScreen.main {
            let x = screen.frame.midX - width / 2
            let y = screen.frame.maxY - screen.safeAreaInsets.top - height
            return NSRect(x: x, y: y, width: width, height: height)
        }

        return NSRect(x: 0, y: 0, width: width, height: height)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
