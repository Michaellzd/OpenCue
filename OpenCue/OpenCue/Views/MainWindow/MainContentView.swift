import SwiftUI
import SwiftData

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(ScrollEngine.self) private var scrollEngine
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var selectedNoteId: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSettings = false

    @AppStorage("opencue.lastOpenedNoteId") private var lastOpenedNoteId: String?

    var body: some View {
        let currentSelectedNote = selectedNote
        let canPlaySelectedNote = selectedNoteHasPlayableContent

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
                .disabled(!canPlaySelectedNote)
                .help("Play/Pause teleprompter (Command-Shift-P)")
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

            if !folders.isEmpty {
                Button("New Note") {
                    createNoteFromEmptyState()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
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

    private var selectedNoteHasPlayableContent: Bool {
        guard let body = selectedNote?.body else { return false }
        return !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        scrollEngine.togglePlayback()
    }

    private func syncScrollEngineForSelection(_ note: Note?) {
        scrollEngine.hasSelectedNote = note != nil
        scrollEngine.textContent = note?.body ?? ""
        scrollEngine.reset()
    }

    private func syncScrollEngineForBodyChange(_ newBody: String?) {
        let body = newBody ?? ""
        let hasPlayableContent = !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !hasPlayableContent {
            scrollEngine.textContent = ""
            scrollEngine.reset()
            return
        }

        guard scrollEngine.state != .playing else { return }
        scrollEngine.textContent = body
        scrollEngine.clampOffsetToContent()
    }

    private func createNoteFromEmptyState() {
        guard let folder = preferredFolderForNewNote() else { return }

        let note = Note(title: "Untitled", folder: folder)
        modelContext.insert(note)
        selectedNoteId = note.id
    }

    private func preferredFolderForNewNote() -> Folder? {
        if let selectedNoteId,
           let selectedNote = findNote(by: selectedNoteId),
           let folder = selectedNote.folder {
            return folder
        }

        return folders.first
    }
}
