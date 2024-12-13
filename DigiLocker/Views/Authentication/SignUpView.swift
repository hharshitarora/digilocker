import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start your 3D scanning journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Sign Up Form
                VStack(spacing: 20) {
                    FloatingTextField(
                        text: $name,
                        placeholder: "Full Name",
                        icon: "person.fill"
                    )
                    
                    FloatingTextField(
                        text: $email,
                        placeholder: "Email",
                        icon: "envelope.fill"
                    )
                    
                    FloatingTextField(
                        text: $password,
                        placeholder: "Password",
                        icon: "lock.fill",
                        isSecure: true
                    )
                    
                    FloatingTextField(
                        text: $confirmPassword,
                        placeholder: "Confirm Password",
                        icon: "lock.fill",
                        isSecure: true
                    )
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authService.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            authService.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"])
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                try await authService.signUp(email: email, password: password, name: name)
            } catch {
                showError = true
            }
            isLoading = false
        }
    }
} 