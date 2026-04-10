import SwiftUI
import SwiftData

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var selectedNoteId: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @AppStorage("opencue.lastOpenedNoteId") private var lastOpenedNoteId: String?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedNoteId: $selectedNoteId)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            if let noteId = selectedNoteId,
               let note = findNote(by: noteId) {
                EditorView(note: note)
            } else {
                emptyState
            }
        }
        .onAppear {
            restoreLastOpenedNote()
        }
        .onChange(of: selectedNoteId) { _, newValue in
            if let newValue {
                lastOpenedNoteId = newValue.uuidString
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    // Agent D will wire the settings sheet
                }) {
                    Image(systemName: "gearshape")
                }
                .help("Settings")

                Button(action: {
                    // Agent C will wire the play/pause action
                }) {
                    Image(systemName: "play.fill")
                }
                .help("Play")
            }
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

    private func restoreLastOpenedNote() {
        guard selectedNoteId == nil,
              let savedId = lastOpenedNoteId,
              let uuid = UUID(uuidString: savedId) else { return }

        if findNote(by: uuid) != nil {
            selectedNoteId = uuid
        }
    }
}
