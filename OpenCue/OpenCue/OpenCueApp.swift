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
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let scrollEngine = ScrollEngine()
    private let appSettings = AppSettings.shared
    private let teleprompterController = TeleprompterWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        syncScrollEngineConfiguration()
        teleprompterController.setup(scrollEngine: scrollEngine, settings: appSettings)

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
        case AppSettings.Keys.scrollSpeed,
             AppSettings.Keys.countdownEnabled,
             AppSettings.Keys.countdownDuration:
            syncScrollEngineConfiguration()
        default:
            break
        }
    }

    private func syncScrollEngineConfiguration() {
        scrollEngine.updateConfiguration(
            speed: appSettings.scrollSpeed,
            countdownEnabled: appSettings.countdownEnabled,
            countdownDuration: appSettings.countdownDuration
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
