import SwiftUI
import RealityKit
import QuickLook
import FirebaseStorage

struct ItemCard: View {
    let item: ScannedItem
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.1))
                
                if isLoading {
                    ProgressView()
                } else if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 160)
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.dateScanned.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
        .task {
            await generateThumbnail()
        }
    }
    
    private func generateThumbnail() async {
        do {
            // Download the model if needed
            let localURL = try await downloadIfNeeded(url: item.modelURL)
            
            // Create a thumbnail using ARView
            let arView = ARView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
            
            // Load and place the model
            let modelEntity = try await Entity.loadAsync(contentsOf: localURL) as? ModelEntity
            guard let modelEntity = modelEntity else {
                throw ModelLoadingError.invalidModelType
            }
            
            // Create an anchor and add the model
            let anchor = AnchorEntity()
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            // Position the model
            modelEntity.position = SIMD3<Float>(0, 0, -0.5)
            
            // Wait a bit for the scene to render
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Take snapshot
            let snapshot = arView.snapshot(saveToHDR: false) { image in
                if let image = image {
                    Task { @MainActor in
                        self.thumbnail = image
                        self.isLoading = false
                    }
                }
            }
        } catch {
            print("Failed to generate thumbnail: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func downloadIfNeeded(url: URL) async throws -> URL {
        // If it's already a local file, return it
        if url.isFileURL {
            return url
        }
        
        // Create a local cache directory if needed
        let cacheDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ModelCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, 
                                               withIntermediateDirectories: true)
        
        // Generate a unique local filename
        let fileName = url.lastPathComponent
        let localURL = cacheDir.appendingPathComponent(fileName)
        
        // If we already have this file cached, return it
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        // Download from Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url.absoluteString)
        
        print("⬇️ Downloading model for thumbnail...")
        _ = try await storageRef.write(toFile: localURL)
        print("✅ Download complete: \(localURL.path)")
        
        return localURL
    }
} 
