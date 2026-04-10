import SwiftUI
import SwiftData

@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .frame(minWidth: 600, minHeight: 400)
                .environment(appSettings)
        }
        .defaultSize(width: 800, height: 550)
        .modelContainer(for: [Folder.self, Note.self])
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let teleprompterController = TeleprompterWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        teleprompterController.setup(with: AppSettings.shared)

        // TODO: When ScrollEngine.swift is added, bind scrollSpeed, countdownEnabled,
        // and countdownDuration from AppSettings into the engine here.
    }
}
