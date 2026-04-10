import AppKit

@MainActor
final class HotkeyManager {
    private enum KeyCode {
        static let p: UInt16 = 35
        static let r: UInt16 = 15
        static let upArrow: UInt16 = 126
        static let downArrow: UInt16 = 125
    }

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let scrollEngine: ScrollEngine
    private let appSettings: AppSettings

    init(scrollEngine: ScrollEngine, appSettings: AppSettings) {
        self.scrollEngine = scrollEngine
        self.appSettings = appSettings
        setupMonitors()
    }

    func teardown() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func setupMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleLocalKeyEvent(event) ? nil : event
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        guard matchesToggleShortcut(event) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.scrollEngine.togglePlayback()
        }
    }

    private func handleLocalKeyEvent(_ event: NSEvent) -> Bool {
        if matchesToggleShortcut(event) {
            scrollEngine.togglePlayback()
            return true
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == [.command], !isTextInputFocused() else { return false }

        switch event.keyCode {
        case KeyCode.upArrow:
            adjustScrollSpeed(by: 1)
            return true
        case KeyCode.downArrow:
            adjustScrollSpeed(by: -1)
            return true
        case KeyCode.r:
            scrollEngine.reset()
            return true
        default:
            return false
        }
    }

    private func matchesToggleShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags == [.command, .shift] && event.keyCode == KeyCode.p
    }

    private func adjustScrollSpeed(by delta: Double) {
        let newSpeed = min(max(appSettings.scrollSpeed + delta, 1), 10)
        appSettings.scrollSpeed = newSpeed
        scrollEngine.setSpeed(newSpeed)
    }

    private func isTextInputFocused() -> Bool {
        guard let firstResponder = NSApp.keyWindow?.firstResponder else { return false }
        return firstResponder is NSTextView
    }
}
