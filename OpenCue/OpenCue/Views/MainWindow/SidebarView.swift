import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @Binding var selectedNoteId: UUID?

    @State private var renamingFolderId: UUID?
    @State private var renamingNoteId: UUID?
    @State private var renameText: String = ""
    @State private var folderToDelete: Folder?
    @State private var showDeleteConfirmation = false
    @State private var expandedFolders: Set<UUID> = []

    var body: some View {
        Group {
            if folders.isEmpty {
                emptyState
            } else {
                folderList
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Create a folder to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("New Folder") {
                createFolder()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Folder List

    private var folderList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedNoteId) {
                ForEach(folders) { folder in
                    folderSection(folder)
                }
            }
            .listStyle(.sidebar)

            Divider()

            Button(action: createFolder) {
                Label("New Folder", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
        .confirmationDialog(
            "Delete Folder",
            isPresented: $showDeleteConfirmation,
            presenting: folderToDelete
        ) { folder in
            Button("Delete \"\(folder.name)\" and all its notes", role: .destructive) {
                deleteFolder(folder)
            }
            Button("Cancel", role: .cancel) {}
        } message: { folder in
            Text("This will permanently delete the folder \"\(folder.name)\" and all \(folder.notes.count) note(s) inside it.")
        }
    }

    // MARK: - Folder Section

    private func folderSection(_ folder: Folder) -> some View {
        let isExpanded = Binding<Bool>(
            get: { expandedFolders.contains(folder.id) },
            set: { newValue in
                if newValue {
                    expandedFolders.insert(folder.id)
                } else {
                    expandedFolders.remove(folder.id)
                }
            }
        )

        return DisclosureGroup(isExpanded: isExpanded) {
            let sortedNotes = folder.notes.sorted { $0.updatedAt > $1.updatedAt }
            ForEach(sortedNotes) { note in
                noteRow(note)
                    .tag(note.id)
            }
        } label: {
            folderLabel(folder)
        }
        .contextMenu {
            Button("Add Note") {
                addNote(to: folder)
            }
            Button("Rename") {
                startRenamingFolder(folder)
            }
            Divider()
            Button("Delete", role: .destructive) {
                folderToDelete = folder
                showDeleteConfirmation = true
            }
        }
        .onAppear {
            // Auto-expand folders on first appearance
            expandedFolders.insert(folder.id)
        }
    }

    // MARK: - Folder Label

    @ViewBuilder
    private func folderLabel(_ folder: Folder) -> some View {
        if renamingFolderId == folder.id {
            TextField("Folder name", text: $renameText, onCommit: {
                commitFolderRename(folder)
            })
            .textFieldStyle(.plain)
            .onAppear {
                renameText = folder.name
            }
            .onExitCommand {
                renamingFolderId = nil
            }
        } else {
            Label(folder.name, systemImage: "folder.fill")
                .foregroundColor(.primary)
        }
    }

    // MARK: - Note Row

    @ViewBuilder
    private func noteRow(_ note: Note) -> some View {
        if renamingNoteId == note.id {
            TextField("Note title", text: $renameText, onCommit: {
                commitNoteRename(note)
            })
            .textFieldStyle(.plain)
            .onAppear {
                renameText = note.title
            }
            .onExitCommand {
                renamingNoteId = nil
            }
        } else {
            Label(note.title, systemImage: "doc.text")
                .foregroundColor(.primary)
                .contextMenu {
                    Button("Rename") {
                        startRenamingNote(note)
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        deleteNote(note)
                    }
                }
        }
    }

    // MARK: - Actions

    private func createFolder() {
        let maxOrder = folders.map(\.sortOrder).max() ?? -1
        let folder = Folder(name: "New Folder", sortOrder: maxOrder + 1)
        modelContext.insert(folder)
        expandedFolders.insert(folder.id)
    }

    private func addNote(to folder: Folder) {
        let note = Note(title: "Untitled", folder: folder)
        modelContext.insert(note)
        selectedNoteId = note.id
        expandedFolders.insert(folder.id)
    }

    private func startRenamingFolder(_ folder: Folder) {
        renameText = folder.name
        renamingFolderId = folder.id
        renamingNoteId = nil
    }

    private func commitFolderRename(_ folder: Folder) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            folder.name = trimmed
        }
        renamingFolderId = nil
    }

    private func startRenamingNote(_ note: Note) {
        renameText = note.title
        renamingNoteId = note.id
        renamingFolderId = nil
    }

    private func commitNoteRename(_ note: Note) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            note.title = trimmed
            note.updatedAt = Date()
        }
        renamingNoteId = nil
    }

    private func deleteFolder(_ folder: Folder) {
        // If the selected note belongs to this folder, clear selection
        if let selectedId = selectedNoteId,
           folder.notes.contains(where: { $0.id == selectedId }) {
            selectedNoteId = nil
        }
        modelContext.delete(folder)
    }

    private func deleteNote(_ note: Note) {
        if selectedNoteId == note.id {
            selectedNoteId = nil
        }
        modelContext.delete(note)
    }
}
