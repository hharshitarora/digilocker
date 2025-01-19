import SwiftUI

struct DigitalChestView: View {
    @StateObject private var dataManager = DataManager()
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var error: Error?
    
    var filteredItems: [ScannedItem] {
        if searchText.isEmpty {
            return dataManager.items
        }
        return dataManager.items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.description.localizedCaseInsensitiveContains(searchText) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading items...")
                } else if let error = error {
                    ContentUnavailableView {
                        Label("Error Loading Items", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item, dataManager: dataManager)) {
                                    ItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .overlay {
                        if dataManager.items.isEmpty {
                            ContentUnavailableView {
                                Label("No Items Yet", systemImage: "cube.box.fill")
                            } description: {
                                Text("Start scanning items to build your digital collection")
                            }
                        } else if filteredItems.isEmpty {
                            ContentUnavailableView {
                                Label("No Results", systemImage: "magnifyingglass")
                            } description: {
                                Text("Try searching with different keywords")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Digital Chest")
            .searchable(text: $searchText, prompt: "Search items...")
        }
        .task {
            do {
                isLoading = true
                await dataManager.loadItems()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
} 