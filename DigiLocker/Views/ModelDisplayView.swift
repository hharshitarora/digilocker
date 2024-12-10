import SwiftUI
import RealityKit

struct ModelDisplayView: View {
    let modelURL: URL
    @Environment(\.dismiss) private var dismiss
    
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
                            dismiss()
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