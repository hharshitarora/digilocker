//
//  ContentView.swift
//  DigiLocker
//
//  Created by Harshit Arora on 11/8/24.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab: Int = 0
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ScanView()
                    .tabItem {
                        Label("Scan", systemImage: "scanner.fill")
                    }
                    .tag(0)
                
                DigitalChestView()
                    .tabItem {
                        Label("My Items", systemImage: "cube.box.fill")
                    }
                    .tag(1)
            }
            .tint(.blue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile.toggle()
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    List {
                        Section {
                            if let user = authService.user {
                                Text(user.email ?? "No email")
                                Text(user.displayName ?? "No name")
                            }
                        }
                        
                        Section {
                            Button(role: .destructive) {
                                try? authService.signOut()
                            } label: {
                                Text("Sign Out")
                            }
                        }
                    }
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct ScanView: View {
    @State private var isScanningActive = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main scanning button with improved visual design
                    Button(action: { isScanningActive = true }) {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue)
                            
                            Text("Start 3D Scan")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // Tips section with improved styling
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Scanning Tips")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            TipRow(icon: "1.circle.fill", text: "Place object on a flat surface")
                            TipRow(icon: "2.circle.fill", text: "Ensure good lighting")
                            TipRow(icon: "3.circle.fill", text: "Slowly move around the object")
                            TipRow(icon: "4.circle.fill", text: "Keep the object centered")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.05))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("3D Scanner")
            .sheet(isPresented: $isScanningActive) {
                if #available(iOS 17.0, *) {
                    ScanningView()
                } else {
                    Text("3D scanning requires iOS 17.0 or later")
                        .padding()
                }
            }
        }
    }
}

struct DigitalChestView: View {
    @StateObject private var dataManager = DataManager()
    @State private var searchText = ""
    
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
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
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
            .navigationTitle("Digital Chest")
            .searchable(text: $searchText, prompt: "Search items...")
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
}

// Supporting Views and Models
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

struct ItemCard: View {
    let item: ScannedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .frame(height: 160)
                .overlay {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    ForEach(item.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct ItemDetailView: View {
    let item: ScannedItem
    let dataManager: DataManager
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ModelViewer(modelURL: item.modelURL)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { isEditing = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(icon: "calendar", title: "Scanned", value: item.dateScanned.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            EditItemSheet(item: item) { updatedItem in
                dataManager.updateItem(updatedItem)
            }
        }
    }
}

// Supporting Views
struct ScanGuidanceIcon: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(isActive ? .blue : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(isActive ? .primary : .secondary)
        }
    }
}

struct TagView: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .blue : .blue.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .blue)
                .clipShape(Capsule())
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                    y: bounds.minY + result.positions[index].y),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                sizes.append(size)
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

// Sheet Views
struct SaveItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var selectedTags: Set<String> = []
    
    let availableTags = ["Furniture", "Electronics", "Art", "Toys", "Memorabilia"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $itemName)
                    TextField("Description", text: $itemDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tags") {
                    ForEach(availableTags, id: \.self) { tag in
                        Button(action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }) {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(itemName.isEmpty)
                }
            }
        }
    }
}

struct EditItemSheet: View {
    let item: ScannedItem
    let onSave: (ScannedItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var itemName: String
    @State private var itemDescription: String
    @State private var selectedTags: Set<String>
    
    init(item: ScannedItem, onSave: @escaping (ScannedItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _itemName = State(initialValue: item.name)
        _itemDescription = State(initialValue: item.description)
        _selectedTags = State(initialValue: Set(item.tags))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $itemName)
                    TextField("Description", text: $itemDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tags") {
                    ForEach(item.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedItem = ScannedItem(
                            id: item.id,
                            name: itemName,
                            description: itemDescription,
                            dateScanned: item.dateScanned,
                            tags: Array(selectedTags),
                            modelURL: item.modelURL
                        )
                        onSave(updatedItem)
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
