import SwiftData
import Foundation

@Model
class Note {
    var id: UUID = UUID()
    var title: String = "Untitled"
    var body: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var folder: Folder?

    init(title: String, folder: Folder) {
        self.id = UUID()
        self.title = title
        self.body = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folder = folder
    }
}
