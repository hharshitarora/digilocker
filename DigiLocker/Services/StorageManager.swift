import FirebaseStorage
import FirebaseAuth

class StorageManager: ObservableObject {
    private let storage = Storage.storage()
    private var storageRoot: StorageReference {
        storage.reference()
    }
    
    // Create a reference for a user's scanned items directory
    private func getUserScansDirectory(userId: String) -> StorageReference {
        storageRoot.child("digilocker/\(userId)/scannedItems")
    }
    
    // Generate a unique filename for a scan
    private func generateScanFileName(userId: String, fileExtension: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(userId)_scan_\(timestamp).\(fileExtension)"
    }
    
    // Upload a scanned model file
    func uploadScanModel(userId: String, fileURL: URL) async throws -> URL {
        let filename = generateScanFileName(userId: userId, fileExtension: "usdz")
        let scanRef = getUserScansDirectory(userId: userId).child(filename)
        
        print(" Starting upload to path: \(scanRef.fullPath)")
        
        // Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "model/usdz"
        metadata.customMetadata = [
            "userId": userId,
            "timestamp": "\(Date().timeIntervalSince1970)"
        ]
        
        _ = try await scanRef.putFileAsync(from: fileURL, metadata: metadata)
        let downloadURL = try await scanRef.downloadURL()
        
        print("✅ Upload complete. Download URL: \(downloadURL.absoluteString)")
        return downloadURL
    }
} 