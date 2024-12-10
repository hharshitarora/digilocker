import SwiftUI
import RealityKit
import QuickLook

// Add ModelLoadingError enum at the top level
enum ModelLoadingError: LocalizedError {
    case invalidModelType
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidModelType:
            return "The loaded model is not of the expected type"
        case .fileNotFound:
            return "The model file was not found"
        }
    }
}

struct ModelViewer: View {
    let modelURL: URL
    @State private var modelEntity: ModelEntity?
    @State private var loadError: Error?
    @State private var currentAngle: Angle = .zero
    @State private var currentScale: Float = 1.0
    
    var body: some View {
        ZStack {
            if let error = loadError {
                // Show error view or QuickLook fallback
                QuickLookPreview(url: modelURL)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // RealityKit viewer
                RealityView { content in
                    let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: .zero))
                    content.add(anchor)
                    
                    Task {
                        do {
                            print("📱 Loading USDZ model from URL: \(modelURL.path)")
                            let model = try await Entity.loadModelAsync(contentsOf: modelURL)
                            
                            if let modelEntity = model as? ModelEntity {
                                print("✅ Model loaded successfully")
                                configureModel(modelEntity)
                                anchor.addChild(modelEntity)
                                addLighting(to: anchor)
                                
                                await MainActor.run {
                                    self.modelEntity = modelEntity
                                }
                            } else {
                                throw ModelLoadingError.invalidModelType
                            }
                        } catch {
                            print("❌ Failed to load model: \(error.localizedDescription)")
                            await MainActor.run {
                                loadError = error
                            }
                        }
                    }
                } update: { content in
                    if let modelEntity = modelEntity {
                        modelEntity.transform.rotation = simd_quatf(angle: Float(currentAngle.radians), axis: [0, 1, 0])
                        modelEntity.scale = [currentScale, currentScale, currentScale]
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            currentAngle += Angle(degrees: value.translation.width)
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentScale = Float(value)
                        }
                )
            }
        }
    }
    
    private func configureModel(_ model: ModelEntity) {
        // Scale model to fit view
        model.scale = [0.5, 0.5, 0.5]
        
        // Enable interactions
        model.generateCollisionShapes(recursive: true)
        model.components[InputTargetComponent.self] = InputTargetComponent()
        
        // Add physics
        model.components[PhysicsBodyComponent.self] = .init(
            massProperties: .default,
            material: .default,
            mode: .static
        )
    }
    
    private func addLighting(to anchor: AnchorEntity) {
        // Add directional light
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 1000
        directionalLight.light.color = .white
        
        // Set up shadow with version compatibility
        if #available(iOS 18.0, *) {
            // For iOS 18 and later, we'll just set the shadow distance
            // since the projection API isn't available yet
            directionalLight.shadow = .init()
            #if swift(<6.0)
            directionalLight.shadow?.maximumDistance = 4
            #endif
        } else {
            // For earlier versions
            directionalLight.shadow = .init()
            directionalLight.shadow?.maximumDistance = 4
        }
        
        directionalLight.position = [0, 2, 0]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        anchor.addChild(directionalLight)
        
        // Add ambient light for better overall illumination
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 500
        ambientLight.light.color = .white
        ambientLight.position = [0, 0, 0]
        anchor.addChild(ambientLight)
    }
}

// Helper Views remain the same
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading model...")
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
            Text("Failed to load model")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

extension ModelEntity {
    static func loadModel(from url: URL) throws -> ModelEntity {
        if let entity = try Entity.load(contentsOf: url) as? ModelEntity {
            return entity
        }
        throw ModelLoadingError.invalidModelType
    }
}

// Add QuickLook preview as fallback
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
} 