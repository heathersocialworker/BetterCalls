import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var favoriteContactIDs: Set<String> = [] // Set of Firestore contact document IDs
    
    private var db = Firestore.firestore()
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                if user != nil {
                    self?.loadFavorites()
                } else {
                    self?.favoriteContactIDs = []
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.user = result?.user
                    self?.isAuthenticated = true
                    self?.loadFavorites()
                }
            }
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // Update the user's display name
                    let changeRequest = result?.user.createProfileChangeRequest()
                    changeRequest?.displayName = "\(firstName) \(lastName)"
                    changeRequest?.commitChanges { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self?.errorMessage = "Account created but failed to set name: \(error.localizedDescription)"
                            } else {
                                self?.user = result?.user
                                self?.isAuthenticated = true
                                self?.loadFavorites()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
            favoriteContactIDs = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = "Password reset email sent successfully"
                }
            }
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.windows.first?.rootViewController else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error = error {
                        print("Google Sign-In error: \(error.localizedDescription)")
                        return
                    }
                    guard let result = result else {
                        print("Google Sign-In: No result")
                        return
                    }
                    let user = result.user
                    guard let idToken = user.idToken?.tokenString else {
                        print("Google Sign-In: Missing idToken")
                        return
                    }
                    let accessToken = user.accessToken.tokenString
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            print("Firebase Google Auth error: \(error.localizedDescription)")
                        } else {
                            print("Signed in with Google: \(authResult?.user.email ?? "?")")
                        }
                    }
                }
    }
    
    // MARK: - Favorites
    func loadFavorites() {
        guard let uid = user?.uid else { return }
        db.collection("favorites").document(uid).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(), let contacts = data["contacts"] as? [String] {
                DispatchQueue.main.async {
                    self?.favoriteContactIDs = Set(contacts)
                }
            } else {
                DispatchQueue.main.async {
                    self?.favoriteContactIDs = []
                }
            }
        }
    }
    
    func addFavorite(contactID: String) {
        guard let uid = user?.uid else { return }
        var newFavorites = favoriteContactIDs
        newFavorites.insert(contactID)
        let userEmail = user?.email ?? ""
        db.collection("favorites").document(uid).setData([
            "contacts": Array(newFavorites),
            "userEmail": userEmail
        ], merge: true) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.favoriteContactIDs = newFavorites
                }
            }
        }
    }
    
    func removeFavorite(contactID: String) {
        guard let uid = user?.uid else { return }
        var newFavorites = favoriteContactIDs
        newFavorites.remove(contactID)
        let userEmail = user?.email ?? ""
        db.collection("favorites").document(uid).setData([
            "contacts": Array(newFavorites),
            "userEmail": userEmail
        ], merge: true) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.favoriteContactIDs = newFavorites
                }
            }
        }
    }
} 
