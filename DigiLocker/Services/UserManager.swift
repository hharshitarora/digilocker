import FirebaseFirestore
import FirebaseAuth

class UserManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUserProfile: UserProfile?
    
    // Create user profile in Firestore
    func createUserProfile(user: User, name: String) async throws {
        let profile = UserProfile(
            id: user.uid,
            name: name,
            email: user.email ?? ""
        )
        
        try await db.collection("users")
            .document(user.uid)
            .setData(try JSONEncoder().encode(profile).asDictionary())
    }
    
    // Fetch user profile
    func fetchUserProfile() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let document = try await db.collection("users")
            .document(userId)
            .getDocument()
        
        guard let data = document.data() else {
            return
        }
        
        self.currentUserProfile = try JSONDecoder().decode(
            UserProfile.self,
            from: JSONSerialization.data(withJSONObject: data)
        )
    }
    
    // Update user's scanned items
    func addScannedItem(_ itemId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        try await db.collection("users")
            .document(userId)
            .updateData([
                "scannedItems": FieldValue.arrayUnion([itemId])
            ])
    }
}

// Helper extension
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
} 