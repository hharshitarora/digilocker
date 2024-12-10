import RealityKit
import SwiftUI
import Foundation
import AVFoundation
import os

@available(iOS 17.0, *)
class ObjectCaptureService: ObservableObject {
    @Published var session: PhotogrammetrySession?
    @Published var scanState: ScanState = .ready
    @Published var progress: Double = 0.0
    @Published var error: Error?
    @Published var isCameraAuthorized = false
    let minimumRequiredImages = 20
    let maximumImages = 70
    private var capturedImages: [Data] = []
    private var scanFolderURL: URL?
    private var inputDirectory: URL?
    private var outputURL: URL?
    
    private let logger = Logger(
        subsystem: "com.yourapp.ObjectCaptureService",
        category: "Photogrammetry"
    )
    
    private let dataManager: DataManager
    
    enum ScanState {
        case ready
        case scanning
        case processing
        case completed
        case failed
    }
    
    enum ObjectCaptureError: LocalizedError {
        case deviceNotSupported
        case scanningFailed(String)
        case processingFailed(String)
        case cameraPermissionDenied
        
        var errorDescription: String? {
            switch self {
            case .deviceNotSupported:
                return "This device does not support 3D object scanning"
            case .scanningFailed(let message):
                return "Scanning failed: \(message)"
            case .processingFailed(let message):
                return "Processing failed: \(message)"
            case .cameraPermissionDenied:
                return "Camera access is required for scanning. Please enable it in Settings."
            }
        }
    }
    
    @MainActor
    init(dataManager: DataManager = DataManager()) {
        self.dataManager = dataManager
        Task {
            await checkCameraAuthorization()
        }
    }
    
    @MainActor
    private func checkCameraAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            self.isCameraAuthorized = true
        case .notDetermined:
            let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            self.isCameraAuthorized = isAuthorized
            if !isAuthorized {
                self.error = ObjectCaptureError.cameraPermissionDenied
                self.scanState = .failed
            }
        case .denied, .restricted:
            self.isCameraAuthorized = false
            self.error = ObjectCaptureError.cameraPermissionDenied
            self.scanState = .failed
        @unknown default:
            break
        }
    }
    
    func startScanning() async {
        print("📸 ObjectCaptureService: Starting scan session")
        
        // Update state synchronously since we're already on the main thread
        guard isCameraAuthorized else {
            print("❌ Camera not authorized")
            self.error = ObjectCaptureError.cameraPermissionDenied
            scanState = .failed
            return
        }
        
        print("✅ Camera authorized, initializing scan")
        scanState = .scanning
        progress = 0.0
        error = nil
        capturedImages.removeAll()
        
        do {
            // Create directories and setup session
            let sessionID = UUID().uuidString
            print("📁 Creating session directory with ID: \(sessionID)")
            
            let baseDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("ObjectCapture")
                .appendingPathComponent(sessionID)
            
            let inputDir = baseDirectory.appendingPathComponent("Input")
            try FileManager.default.createDirectory(
                at: inputDir,
                withIntermediateDirectories: true
            )
            
            let outputDir = baseDirectory.appendingPathComponent("Output")
            try FileManager.default.createDirectory(
                at: outputDir,
                withIntermediateDirectories: true
            )
            
            let checkpointsDir = baseDirectory.appendingPathComponent("Checkpoints")
            try FileManager.default.createDirectory(
                at: checkpointsDir,
                withIntermediateDirectories: true
            )
            
            // Update state synchronously
            self.inputDirectory = inputDir
            self.outputURL = outputDir.appendingPathComponent("model.usdz")
            
            print("✅ Scan session initialized successfully")
            logger.info("Directories created successfully, ready for capturing")
            
        } catch {
            print("❌ Failed to initialize scan session: \(error.localizedDescription)")
            self.error = ObjectCaptureError.scanningFailed(error.localizedDescription)
            scanState = .failed
            logger.error("Failed to create directories: \(error.localizedDescription)")
        }
    }
    
    func captureImage(_ imageData: Data) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            print("📸 Capturing image \(self.capturedImages.count + 1)")
            logger.info("Starting image capture. Current count: \(self.capturedImages.count)")
            
            guard self.capturedImages.count < self.maximumImages else {
                logger.warning("Maximum number of images reached (\(self.maximumImages))")
                self.error = ObjectCaptureError.scanningFailed("Maximum number of images reached")
                self.scanState = .failed
                return
            }
            
            guard let inputDirectory = self.inputDirectory else {
                logger.error("Input directory not available")
                self.error = ObjectCaptureError.scanningFailed("No input directory available")
                self.scanState = .failed
                return
            }
            
            do {
                // Save image with sequential naming using JPEG format
                let imageName = String(format: "IMG_%04d.jpg", self.capturedImages.count + 1)
                let imageURL = inputDirectory.appendingPathComponent(imageName)
                
                // Save the JPEG data directly
                try imageData.write(to: imageURL)
                print("💾 Saved image \(imageName)")
                logger.info("Saved image \(imageName) to disk")
                
                // Append image data to the array
                self.capturedImages.append(imageData)
                
                // Update progress
                self.progress = Double(self.capturedImages.count) / Double(self.minimumRequiredImages)
                logger.info("Updated progress: \(self.progress)")
                
                // Check if we have enough images to process
                if self.capturedImages.count >= self.minimumRequiredImages {
                    print("🎯 Minimum images reached (\(self.minimumRequiredImages)), starting processing")
                    logger.info("Minimum images reached, starting processing")
                    
                    // Stop the camera session before processing
                    if let arView = ScanningView.shared?.arView {
                        print("📸 Stopping camera session")
                        arView.session.pause()
                        // Don't remove the view since we still want to show the UI
                    }
                    
                    self.scanState = .processing
                    await self.finishCapture()
                }
            } catch {
                print("❌ Failed to save image: \(error.localizedDescription)")
                logger.error("Failed to save image: \(error.localizedDescription)")
                self.error = ObjectCaptureError.scanningFailed(error.localizedDescription)
                self.scanState = .failed
            }
        }
    }
    
    @MainActor
    func finishCapture() async {
        logger.info("Starting finishCapture")
        guard let inputDirectory = inputDirectory else {
            logger.error("Input directory not available during processing")
            error = ObjectCaptureError.processingFailed("Input directory not available")
            scanState = .failed
            return
        }
        
        do {
            logger.info("Creating PhotogrammetrySession configuration")
            var configuration = PhotogrammetrySession.Configuration()
            configuration.checkpointDirectory = inputDirectory.appendingPathComponent("Checkpoints")
            configuration.sampleOrdering = .sequential
            configuration.featureSensitivity = .normal
            
            // Verify input images
            let imageURLs = try FileManager.default.contentsOfDirectory(
                at: inputDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension.lowercased() == "jpg" }
            
            logger.info("Found \(imageURLs.count) images for processing")
            
            guard imageURLs.count >= minimumRequiredImages else {
                throw ObjectCaptureError.processingFailed("Not enough valid images found")
            }
            
            // Create output directory in Documents folder
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outputDirectory = documentsDirectory.appendingPathComponent("3DModels")
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            
            // Set output URL with unique name
            let modelFileName = "model_\(UUID().uuidString).usdz"
            let modelURL = outputDirectory.appendingPathComponent(modelFileName)
            self.outputURL = modelURL
            
            logger.info("Initializing PhotogrammetrySession")
            let session = try PhotogrammetrySession(
                input: inputDirectory,
                configuration: configuration
            )
            self.session = session
            
            // Create and process the request
            let request = PhotogrammetrySession.Request.modelFile(
                url: modelURL,
                detail: .reduced,
                geometry: nil
            )
            
            logger.info("Starting model processing")
            try await session.process(requests: [request])
            
            // Monitor session outputs
            for try await output in session.outputs {
                switch output {
                case .inputComplete:
                    logger.info("✅ Input processing complete")
                    self.scanState = .processing
                    
                case .requestProgress(_, let fractionComplete):
                    logger.info("📊 Processing progress: \(fractionComplete)")
                    self.progress = fractionComplete
                    
                case .processingComplete:
                    logger.info("🎉 Processing complete!")
                    if FileManager.default.fileExists(atPath: modelURL.path) {
                        logger.info("💾 Model saved at: \(modelURL.path)")
                        self.scanState = .completed
                        
                        // Save to DataManager
                        let newItem = ScannedItem(
                            name: "Scanned Object",
                            description: "3D scan created on \(Date().formatted())",
                            tags: ["3D Scan"],
                            modelURL: modelURL
                        )
                        self.dataManager.addItem(newItem)
                    }
                    
                case .requestError(_, let error):
                    logger.error("❌ Request error: \(error.localizedDescription)")
                    throw ObjectCaptureError.processingFailed(error.localizedDescription)
                    
                case .invalidSample(let id, let reason):
                    logger.warning("⚠️ Invalid sample \(id): \(reason)")
                    
                case .skippedSample(let id):
                    logger.warning("⚠️ Skipped sample: \(id)")
                    
                case .automaticDownsampling:
                    logger.info("📉 Automatic downsampling applied")
                    
                case .requestComplete:
                    logger.info("✅ Request completed")
                    
                @unknown default:
                    logger.warning("⚠️ Unhandled output type: \(String(describing: output))")
                }
            }
            
        } catch {
            logger.error("❌ Processing failed with error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = ObjectCaptureError.processingFailed(error.localizedDescription)
                self.scanState = .failed
            }
        }
    }
    
    func getModelURL() -> URL? {
        guard let url = outputURL,
              FileManager.default.fileExists(atPath: url.path) else {
            logger.error("Model file not found")
            return nil
        }
        return url
    }
    
    func cancelScanning() {
        Task {
            logger.info("Cancelling scan")
            await session?.cancel()
            
            // Stop camera session
            if let arView = ScanningView.shared?.arView {
                print("📸 Stopping camera session")
                arView.session.pause()
            }
            
            cleanup()
            scanState = .ready
            progress = 0.0
        }
    }
    
    var capturedImageCount: Int { capturedImages.count }
    
    // Add cleanup method
    private func cleanup() {
        logger.info("Starting cleanup")
        // Only clean up temporary directories
        if let inputDirectory = inputDirectory {
            do {
                try FileManager.default.removeItem(at: inputDirectory)
                logger.info("Cleaned up input directory")
            } catch {
                logger.error("Failed to cleanup directory: \(error.localizedDescription)")
            }
        }
        capturedImages.removeAll()
        session = nil
        inputDirectory = nil
        scanFolderURL = nil
        // Don't clear outputURL as it points to the saved model
    }
    
    // Add a method to check if the model exists
    func modelExists() -> Bool {
        guard let url = outputURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // Add a method to check if model is ready
    func isModelReady() -> Bool {
        guard let url = outputURL,
              FileManager.default.fileExists(atPath: url.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > 0 else {
            return false
        }
        return true
    }
    
    // Add a method to get the final model URL
    func getFinalModelURL() -> URL? {
        if case .completed = scanState,
           let url = outputURL,
           FileManager.default.fileExists(atPath: url.path) {
            print("📱 Model file exists at path: \(url.path)")
            print("📊 File size: \(try? FileManager.default.attributesOfItem(atPath: url.path)[.size] ?? 0) bytes")
            return url
        }
        print("❌ Model file not found or processing not complete")
        return nil
    }
    
    // Add method to stop camera session
    private func stopCameraSession() async {
        if let arView = ScanningView.shared?.arView {
            arView.session.pause()
            arView.removeFromSuperview()
        }
    }
}
