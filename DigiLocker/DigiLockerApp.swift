//
//  DigiLockerApp.swift
//  DigiLocker
//
//  Created by Harshit Arora on 11/8/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let config = Configuration.shared
        
        // If no configuration is found, fall back to default Firebase configuration
        if config.firebaseApiKey.isEmpty {
            FirebaseApp.configure()
        } else {
            let options = FirebaseOptions(
                googleAppID: config.firebaseAppId,
                gcmSenderID: "272940680090"  // Use your actual sender ID
            )
            options.apiKey = config.firebaseApiKey
            options.projectID = config.firebaseProjectId
            options.storageBucket = config.firebaseStorageBucket
            
            FirebaseApp.configure(options: options)
        }
        return true
    }
}

@main
struct DigiLockerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                        .onAppear {
                            print("🔥 Showing ContentView - User is authenticated")
                        }
                } else {
                    LoginView()
                        .environmentObject(authService)
                        .onAppear {
                            print("🔥 Showing LoginView - User is not authenticated")
                        }
                }
            }
            .onChange(of: authService.isAuthenticated) { newValue in
                print("🔥 Authentication state changed to: \(newValue)")
            }
        }
    }
}
