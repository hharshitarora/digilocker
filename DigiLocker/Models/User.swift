import Foundation

struct UserProfile: Codable {
    let id: String  // This will be the Firebase uid
    var name: String
    var email: String
    var dateJoined: Date
    var scannedItems: [String]  // Array of scanned item IDs
    
    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.dateJoined = Date()
        self.scannedItems = []
    }
    
    // Add coding keys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case dateJoined
        case scannedItems
    }
    
    // Custom decoder for handling Date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        
        // Handle date decoding
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .dateJoined) {
            dateJoined = Date(timeIntervalSince1970: timestamp)
        } else {
            dateJoined = Date()
        }
        
        scannedItems = try container.decode([String].self, forKey: .scannedItems)
    }
    
    // Custom encoder for handling Date
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(dateJoined.timeIntervalSince1970, forKey: .dateJoined)
        try container.encode(scannedItems, forKey: .scannedItems)
    }
} 