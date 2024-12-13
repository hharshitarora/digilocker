import SwiftUI
import RealityKit

struct ModelDisplayView: View {
    let modelURL: URL
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTab") private var selectedTab: Int = 0  // Add this to track selected tab
    @Environment(\.presentationMode) private var presentationMode // Add this
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Model viewer
                ModelViewer(modelURL: modelURL)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        print("📱 Attempting to load model from: \(modelURL.path)")
                    }
                
                // Controls overlay
                VStack {
                    // Top bar with controls
                    HStack {
                        Button("Done") {
                            selectedTab = 1  // Switch to "My Items" tab (index 1)
                            dismiss() // Dismiss current view
                            // Dismiss the entire scanning sheet
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.dismiss(animated: true)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Add export button
                        ShareLink(item: modelURL) {
                            Image(systemName: "square.and.arrow.up")
                                .padding()
                        }
                    }
                    .background(.ultraThinMaterial)
                    
                    Spacer()
                    
                    // Bottom instructions
                    Text("Drag to rotate • Pinch to zoom")
                        .font(.caption)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
    }
} 