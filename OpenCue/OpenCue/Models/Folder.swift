import SwiftData
import Foundation

@Model
class Folder {
    var id: UUID = UUID()
    var name: String = "New Folder"
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    var notes: [Note] = []

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
