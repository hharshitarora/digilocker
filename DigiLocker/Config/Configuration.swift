import Foundation

struct Configuration {
    static let shared = Configuration()
    
    let firebaseApiKey: String
    let firebaseProjectId: String
    let firebaseStorageBucket: String
    let firebaseAppId: String
    
    private init() {
        // First try to load from Configuration.plist
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.firebaseApiKey = config["FIREBASE_API_KEY"] as? String ?? ""
            self.firebaseProjectId = config["FIREBASE_PROJECT_ID"] as? String ?? ""
            self.firebaseStorageBucket = config["FIREBASE_STORAGE_BUCKET"] as? String ?? ""
            self.firebaseAppId = config["FIREBASE_APP_ID"] as? String ?? ""
        }
        // Fallback to GoogleService-Info.plist if Configuration.plist is not found
        else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.firebaseApiKey = config["API_KEY"] as? String ?? ""
            self.firebaseProjectId = config["PROJECT_ID"] as? String ?? ""
            self.firebaseStorageBucket = config["STORAGE_BUCKET"] as? String ?? ""
            self.firebaseAppId = config["GOOGLE_APP_ID"] as? String ?? ""
        }
        // If neither file is found, use empty strings (for development)
        else {
            print("⚠️ Warning: No configuration file found. Using empty values.")
            self.firebaseApiKey = ""
            self.firebaseProjectId = ""
            self.firebaseStorageBucket = ""
            self.firebaseAppId = ""
        }
    }
} 