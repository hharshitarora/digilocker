import FirebaseFirestore
import FirebaseAuth

class DataManager: ObservableObject {
    @Published var items: [ScannedItem] = []
    private let db = Firestore.firestore()
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
        loadItems()
    }
    
    func loadItems() {
        guard let userId = authService.currentUserId else { return }
        
        // Listen for real-time updates
        db.collection("scannedItems")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.items = documents.compactMap { document in
                    try? document.data(as: ScannedItem.self)
                }
            }
    }
    
    func addItem(_ item: ScannedItem) {
        do {
            try db.collection("scannedItems")
                .document(item.id.uuidString)
                .setData(from: item)
            
            // Update local array
            items.append(item)
        } catch {
            print("Error adding item: \(error.localizedDescription)")
        }
    }
    
    func updateItem(_ item: ScannedItem) {
        do {
            try db.collection("scannedItems")
                .document(item.id.uuidString)
                .setData(from: item)
            
            // Update local array
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
        } catch {
            print("Error updating item: \(error.localizedDescription)")
        }
    }
    
    func deleteItem(_ item: ScannedItem) {
        db.collection("scannedItems")
            .document(item.id.uuidString)
            .delete() { error in
                if let error = error {
                    print("Error removing item: \(error.localizedDescription)")
                } else {
                    // Remove from local array
                    self.items.removeAll { $0.id == item.id }
                }
            }
    }
} 