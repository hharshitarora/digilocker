import SwiftUI
import RealityKit
import ARKit
import SafariServices

struct ScanningView: View {
    static var shared: ScanningView?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var captureService = ObjectCaptureService()
    @State var arView = ARView(frame: .zero)
    @State private var showingSettings = false
    @State private var captureEnabled = false
    @State private var showingModelViewer = false
    
    init() {
        ScanningView.shared = self
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if captureService.isCameraAuthorized {
                    // AR View for scanning
                    ARViewContainer(arView: arView) { imageData in
                        // Only capture if enabled (prevents accidental captures)
                        if captureEnabled {
                            captureService.captureImage(imageData)
                            // Disable capture until next press
                            captureEnabled = false
                        }
                    }
                    .edgesIgnoringSafeArea(.all)

                    // Overlay UI
                    VStack {
                        // Top status bar
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.white)
                            Text("\(captureService.capturedImageCount) shots")
                                .foregroundStyle(.white)
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)

                        Spacer()

                        // Scanning guidance and controls
                        VStack(spacing: 20) {
                            switch captureService.scanState {
                            case .ready:
                                ScanningPrompt {
                                    Task {
                                        print("🚀 Starting scan session...")
                                        await captureService.startScanning()
                                        print("📱 Scan session started, ready for captures")
                                        // Enable capture after session starts
                                        captureEnabled = true
                                    }
                                }
                            case .scanning:
                                // Capture UI
                                VStack(spacing: 16) {
                                    // Progress indicator
                                    ScanningProgress(
                                        progress: captureService.progress,
                                        imageCount: captureService.capturedImageCount,
                                        minimumRequired: captureService.minimumRequiredImages
                                    )
                                    
                                    // Capture button
                                    CaptureButton {
                                        captureEnabled = true
                                        if let coordinator = arView.session.delegate as? ARViewContainer.Coordinator {
                                            coordinator.captureImage()
                                        }
                                    }
                                    
                                    // Guidance text
                                    GuidanceView(imageCount: captureService.capturedImageCount)
                                }
                                .padding(.bottom, 30)
                            case .processing:
                                ZStack {
                                    // Dim the background
                                    Color.black.opacity(0.5)
                                        .edgesIgnoringSafeArea(.all)
                                    
                                    ProcessingView(progress: captureService.progress)
                                }
                                .transition(.opacity)
                                .animation(.easeInOut, value: captureService.scanState)
                            case .completed:
                                if let modelURL = captureService.getFinalModelURL() {
                                    VStack(spacing: 16) {
                                        CompletionView()
                                        
                                        NavigationLink {
                                            ModelDisplayView(modelURL: modelURL)
                                                .navigationBarBackButtonHidden(true)
                                        } label: {
                                            Text("View 3D Model")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .frame(height: 50)
                                                .frame(maxWidth: .infinity)
                                                .background(.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    .padding()
                                } else {
                                    ProcessingView(progress: captureService.progress)
                                }
                            case .failed:
                                ErrorStateView(error: captureService.error, showingSettings: $showingSettings)
                            }
                        }
                        .padding()
                    }
                } else {
                    CameraPermissionView(showingSettings: $showingSettings)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        captureService.cancelScanning()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingModelViewer) {
                if let modelURL = captureService.getModelURL() {
                    ModelViewer(modelURL: modelURL)
                }
            }
        }
    }
}

// New Components
struct CaptureButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .frame(width: 74, height: 74)
                
                // Inner circle
                Circle()
                    .fill(.white)
                    .frame(width: 60, height: 60)
            }
        }
        .frame(width: 80, height: 80) // Hit target size (44pt minimum)
        .contentShape(Circle())
    }
}

struct GuidanceView: View {
    let imageCount: Int
    
    var guidanceText: String {
        if imageCount == 0 {
            return "Position object in the center and tap to capture"
        } else if imageCount < 10 {
            return "Capture the object from different angles"
        } else {
            return "Move higher/lower for complete coverage"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text(guidanceText)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Scan Complete!")
                .font(.headline)
            Text("Your 3D model is ready")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ErrorStateView: View {
    let error: Error?
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.red)
            
            if let error = error {
                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                
                if let captureError = error as? ObjectCaptureService.ObjectCaptureError,
                   case .cameraPermissionDenied = captureError {
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ProcessingView: View {
    let progress: Double
    @State private var processingStage = "Initializing..."
    @State private var estimatedTimeRemaining: TimeInterval = 0
    @State private var startTime = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
                
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .bold()
                    Text(processingStage)
                        .font(.caption)
                }
            }
            .frame(width: 150, height: 150)
            
            // Processing stage
            Text(processingStage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Time estimate
            if estimatedTimeRemaining > 0 {
                Text("Estimated time remaining: \(formatTime(estimatedTimeRemaining))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: progress) { newProgress in
            updateProcessingStage(progress: newProgress)
            updateTimeEstimate(progress: newProgress)
        }
        .onAppear {
            startTime = Date()
        }
    }
    
    private func updateProcessingStage(progress: Double) {
        if progress < 0.2 {
            processingStage = "Analyzing images..."
        } else if progress < 0.4 {
            processingStage = "Generating point cloud..."
        } else if progress < 0.6 {
            processingStage = "Creating mesh..."
        } else if progress < 0.8 {
            processingStage = "Adding textures..."
        } else {
            processingStage = "Finalizing model..."
        }
    }
    
    private func updateTimeEstimate(progress: Double) {
        guard progress > 0 else { return }
        let timeElapsed = Date().timeIntervalSince(startTime)
        estimatedTimeRemaining = (timeElapsed / progress) * (1 - progress)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ScanningPrompt: View {
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Position the object in the center")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                print("🔵 Start Scanning button tapped")
                action()
            }) {
                Text("Start 3D Scan")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ScanningProgress: View {
    let progress: Double
    let imageCount: Int
    let minimumRequired: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: progress)
                .tint(.blue)
            
            // Image count
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundStyle(.blue)
                Text("\(imageCount) of \(minimumRequired) images")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Guidance text
            Text("Capture from different angles")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    var onImageCaptured: ((Data) -> Void)?
    
    func makeUIView(context: Context) -> ARView {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        arView.session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
        
        // Set the coordinator as the session delegate
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func captureImage() {
            guard let currentFrame = parent.arView.session.currentFrame else { return }
            
            // Get high quality image data
            let imageResolution = currentFrame.camera.imageResolution
            let pixelBuffer = currentFrame.capturedImage
            
            // Convert to high quality JPEG
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            
            let uiImage = UIImage(cgImage: cgImage)
            if let imageData = uiImage.jpegData(compressionQuality: 0.9) {
                parent.onImageCaptured?(imageData)
            }
        }
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct CameraPermissionView: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please allow camera access to use the 3D scanner")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                showingSettings = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// Add this helper view for opening Settings
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
