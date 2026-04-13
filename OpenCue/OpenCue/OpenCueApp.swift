import AppKit
import SwiftUI
import SwiftData

@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environment(appSettings)
                .environment(appDelegate.scrollEngine)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 800, height: 550)
        .modelContainer(for: [Folder.self, Note.self])
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About OpenCue") {
                    showAboutPanel()
                }
            }
        }
    }

    private func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(
            options: [
                .applicationName: "OpenCue",
                .applicationVersion: "1.0.0",
                .version: "1.0.0"
            ]
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let scrollEngine = ScrollEngine()
    private let appSettings = AppSettings.shared
    private let teleprompterController = TeleprompterWindowController()
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        syncScrollEngineConfiguration()
        hotkeyManager = HotkeyManager(scrollEngine: scrollEngine, appSettings: appSettings)

        if shouldShowTeleprompterOverlay() {
            teleprompterController.setup(scrollEngine: scrollEngine, settings: appSettings)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppSettingsDidChange(_:)),
            name: .appSettingsDidChange,
            object: appSettings
        )
    }

    @objc
    private func handleAppSettingsDidChange(_ notification: Notification) {
        guard let key = notification.userInfo?[AppSettings.changeKeyUserInfoKey] as? String else {
            syncScrollEngineConfiguration()
            return
        }

        switch key {
        case AppSettings.Keys.scrollSpeed:
            syncScrollEngineConfiguration()
        default:
            break
        }
    }

    private func syncScrollEngineConfiguration() {
        scrollEngine.updateConfiguration(speed: appSettings.scrollSpeed)
    }

    private func shouldShowTeleprompterOverlay() -> Bool {
        guard NotchDetector.detect() == nil else { return true }

        let alert = NSAlert()
        alert.messageText = "Notch Required"
        alert.informativeText = "OpenCue requires a MacBook with a notch display. External monitors are not supported."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Continue Anyway")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }

        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.teardown()
        NotificationCenter.default.removeObserver(self)
    }
}
