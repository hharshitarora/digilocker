import FirebaseAuth
import FirebaseCore

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    var currentUserId: String? {
        return user?.uid
    }
    
    init() {
        print("🔥 Initializing AuthenticationService")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("🔥 Auth state changed - User: \(user?.email ?? "nil")")
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔥 Attempting sign in with email: \(email)")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("🔥 Sign in successful for user: \(result.user.email ?? "")")
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        print("🔥 Attempting sign up with email: \(email)")
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            print("🔥 Sign up successful for user: \(result.user.email ?? "")")
            print("🔥 User ID: \(result.user.uid)")
            
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Sign up failed: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
    }
} 