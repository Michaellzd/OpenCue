import AppKit
import SwiftUI

@MainActor
final class TeleprompterWindowController: NSObject {
    private(set) var panel: NSPanel?
    private weak var settings: AppSettings?

    /// Create and show the teleprompter panel positioned over the notch.
    func setup(with settings: AppSettings) {
        self.settings = settings

        let panelWidth = settings.overlayWidth
        let panelHeight = settings.overlayHeight

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

        // Click-through — mouse events pass to windows behind it
        panel.ignoresMouseEvents = true

        // Don't appear in Mission Control, Dock, or Cmd+Tab
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Transparent / no chrome
        panel.backgroundColor = NSColor.white.withAlphaComponent(settings.opacity)
        panel.isOpaque = false
        panel.hasShadow = false

        // Host the SwiftUI overlay inside the panel
        let hostingView = NSHostingView(rootView: TeleprompterOverlay().environment(settings))
        panel.contentView = hostingView

        // Position over the notch
        positionPanel(panel, width: panelWidth, height: panelHeight)

        panel.orderFrontRegardless()
        self.panel = panel
        observeSettings()
    }

    /// Position the panel centered on the notch, extending downward.
    private func positionPanel(_ panel: NSPanel, width: CGFloat, height: CGFloat) {
        if let notch = NotchDetector.detect() {
            // Center horizontally on the notch
            let x = notch.x + (notch.width - width) / 2
            // Place top edge at the bottom of the notch (panel extends downward)
            let y = notch.y - height
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // No notch found — place at top-center of the main screen as fallback
            if let screen = NSScreen.main {
                let x = screen.frame.midX - width / 2
                let y = screen.frame.maxY - screen.safeAreaInsets.top - height
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
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

    @objc
    private func handleSettingsDidChange(_ notification: Notification) {
        applySettings()
    }

    private func applySettings() {
        guard let panel, let settings else { return }

        panel.backgroundColor = NSColor.white.withAlphaComponent(settings.opacity)

        let newFrame = frameForPanel(
            width: settings.overlayWidth,
            height: settings.overlayHeight
        )
        panel.setFrame(newFrame, display: true, animate: false)
    }

    private func frameForPanel(width: CGFloat, height: CGFloat) -> NSRect {
        if let notch = NotchDetector.detect() {
            let x = notch.x + (notch.width - width) / 2
            let y = notch.y - height
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
