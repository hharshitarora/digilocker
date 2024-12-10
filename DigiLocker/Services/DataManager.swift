import Foundation

class DataManager: ObservableObject {
    @Published var items: [ScannedItem] = []
    private let saveKey = "scanned_items"
    
    init() {
        loadItems()
    }
    
    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(saveKey).json")
    }
    
    func loadItems() {
        do {
            let data = try Data(contentsOf: saveURL)
            items = try JSONDecoder().decode([ScannedItem].self, from: data)
        } catch {
            print("Error loading items: \(error)")
            items = []
        }
    }
    
    func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: saveURL)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func addItem(_ item: ScannedItem) {
        items.append(item)
        saveItems()
    }
    
    func updateItem(_ item: ScannedItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    func deleteItem(_ item: ScannedItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
} 