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
        FirebaseApp.configure()
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
