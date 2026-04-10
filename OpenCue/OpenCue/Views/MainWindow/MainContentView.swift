import SwiftUI
import SwiftData

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(ScrollEngine.self) private var scrollEngine

    @State private var selectedNoteId: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSettings = false

    @AppStorage("opencue.lastOpenedNoteId") private var lastOpenedNoteId: String?

    var body: some View {
        let currentSelectedNote = selectedNote

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedNoteId: $selectedNoteId)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            if let note = currentSelectedNote {
                EditorView(note: note)
            } else {
                emptyState
            }
        }
        .onAppear {
            restoreLastOpenedNote()
            syncScrollEngineForSelection(selectedNote)
        }
        .onChange(of: selectedNoteId) { _, newValue in
            if let newValue {
                lastOpenedNoteId = newValue.uuidString
            } else {
                lastOpenedNoteId = nil
            }

            syncScrollEngineForSelection(selectedNote)
        }
        .onChange(of: currentSelectedNote?.body) { _, newBody in
            syncScrollEngineForBodyChange(newBody)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                }
                .help("Settings")

                Button(action: togglePlayback) {
                    Image(systemName: scrollEngine.state == .playing ? "pause.fill" : "play.fill")
                        .foregroundColor(scrollEngine.state == .playing ? .blue : .primary)
                }
                .disabled(currentSelectedNote == nil || currentSelectedNote?.body.isEmpty == true)
                .help("Play/Pause teleprompter")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(settings)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Select or create a note")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func findNote(by id: UUID) -> Note? {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private var selectedNote: Note? {
        guard let selectedNoteId else { return nil }
        return findNote(by: selectedNoteId)
    }

    private func restoreLastOpenedNote() {
        guard selectedNoteId == nil,
              let savedId = lastOpenedNoteId,
              let uuid = UUID(uuidString: savedId) else { return }

        if findNote(by: uuid) != nil {
            selectedNoteId = uuid
        }
    }

    private func togglePlayback() {
        switch scrollEngine.state {
        case .idle, .finished:
            scrollEngine.reset()
            scrollEngine.play()
        case .playing:
            scrollEngine.pause()
        case .paused:
            scrollEngine.play()
        case .countdown:
            scrollEngine.reset()
        }
    }

    private func syncScrollEngineForSelection(_ note: Note?) {
        scrollEngine.textContent = note?.body ?? ""
        scrollEngine.reset()
    }

    private func syncScrollEngineForBodyChange(_ newBody: String?) {
        guard scrollEngine.state != .playing else { return }
        scrollEngine.textContent = newBody ?? ""
        scrollEngine.clampOffsetToContent()
    }
}
