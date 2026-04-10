import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var note: Note

    @State private var saveTask: Task<Void, Never>?
    @FocusState private var isBodyFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title field
            TextField("Note title", text: $note.title)
                .font(.title2)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .onChange(of: note.title) { _, _ in
                    scheduleSave()
                }

            Divider()
                .padding(.horizontal, 16)

            // Body editor
            TextEditor(text: $note.body)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .focused($isBodyFocused)
                .onChange(of: note.body) { _, _ in
                    scheduleSave()
                }

            // Bottom bar with word count
            HStack {
                Spacer()
                Text(wordCountText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.textBackgroundColor))
        .onAppear {
            isBodyFocused = true
        }
        .onDisappear {
            // Ensure pending save completes
            saveTask?.cancel()
            note.updatedAt = Date()
        }
    }

    private var wordCountText: String {
        let words = note.body
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
        return "\(words) word\(words == 1 ? "" : "s")"
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                note.updatedAt = Date()
            }
        }
    }
}
