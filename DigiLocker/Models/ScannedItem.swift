import Foundation

struct ScannedItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var dateScanned: Date
    var tags: [String]
    var modelURL: URL
    
    init(id: UUID = UUID(), name: String, description: String, dateScanned: Date = Date(), tags: [String], modelURL: URL) {
        self.id = id
        self.name = name
        self.description = description
        self.dateScanned = dateScanned
        self.tags = tags
        self.modelURL = modelURL
    }
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScannedItem, rhs: ScannedItem) -> Bool {
        lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, dateScanned, tags, modelURL
    }
} 