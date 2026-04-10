import SwiftUI
import FirebaseAuth
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        ZStack {
            // Background based on color scheme
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("BetterCalls")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Mental Health Support")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                
                // Login Form
                VStack(spacing: 24) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Name Fields (only show during sign up)
                    if isSignUp {
                        HStack(spacing: 12) {
                            // First Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                    TextField("First name", text: $firstName)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.words)
                                        .disableAutocorrection(true)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Last Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                    TextField("Last name", text: $lastName)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.words)
                                        .disableAutocorrection(true)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Sign In/Up Button
                        Button(action: {
                            if isSignUp {
                                authManager.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
                            } else {
                                authManager.signIn(email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: isSignUp ? "person.badge.plus" : "person.fill")
                                }
                                
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && (firstName.isEmpty || lastName.isEmpty)))
                        
                        // Google Sign In Button (using GoogleSignInButtonViewModel)
                        Button(action: {
                            authManager.signInWithGoogle()
                        }) {
                            HStack {
                                Image("google_logo")
                                    .frame(width: 5, height: 5)
                                Spacer().frame(width: 20)
                                Text("Sign in with Google")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95)) // #F2F2F2
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Toggle Sign In/Up Button
                        Button(action: {
                            isSignUp.toggle()
                            authManager.errorMessage = nil
                            if !isSignUp {
                                firstName = ""
                                lastName = ""
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Create an account")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Forgot Password Button
                        if !isSignUp {
                            Button(action: {
                                showingPasswordReset = true
                            }) {
                                Text("Forgot Password?")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .alert("Reset Password", isPresented: $showingPasswordReset) {
            TextField("Enter your email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            Button("Send Reset Email") {
                authManager.resetPassword(email: email)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address to receive a password reset link.")
        }
    }
}

#Preview {
    LoginView()
} 
