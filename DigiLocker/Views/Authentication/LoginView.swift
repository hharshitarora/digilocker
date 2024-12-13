import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showError = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo/App Name
                        VStack(spacing: 12) {
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue)
                            
                            Text("DigiLocker")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 60)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email field
                            FloatingTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope.fill"
                            )
                            
                            // Password field
                            FloatingTextField(
                                text: $password,
                                placeholder: "Password",
                                icon: "lock.fill",
                                isSecure: true
                            )
                            
                            // Sign In Button
                            Button(action: signIn) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.top)
                            
                            // Sign Up Link
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Don't have an account? ")
                                    .foregroundStyle(.secondary) +
                                Text("Sign Up")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                            .padding(.top)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authService.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                showError = true
            }
            isLoading = false
        }
    }
}

// Custom TextField with floating label
struct FloatingTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
} 