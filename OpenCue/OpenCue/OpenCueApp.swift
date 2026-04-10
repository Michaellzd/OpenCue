import SwiftUI
import SwiftData

@main
struct OpenCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 800, height: 550)
        .modelContainer(for: [Folder.self, Note.self])
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let teleprompterController = TeleprompterWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        teleprompterController.setup()
    }
}
