import SwiftUI
import FirebaseAuth

struct ModernSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthenticationManager
    @Binding var isAuthenticated: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.076, green: 0.153, blue: 0.278),
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.076, green: 0.153, blue: 0.278)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 20)
                                
                                TextField("name@example.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 20)
                                
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .foregroundColor(.white)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // ✅ Forgot Password Button
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Button(action: { Task { await handleSignIn() } }) {
                            Group {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(Styles.Colors.mainColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .cornerRadius(16)
                        }
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                        .padding(.top, 8)
                    }
                    .padding(28)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.7))
                        Button(action: { dismiss() }) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .font(.subheadline)
                    .padding(.top, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            ModernForgotPasswordView(authManager: authManager)
        }
    }
    
    private func handleSignIn() async {
        do {
            try await authManager.signIn(email: email, password: password)
            await MainActor.run {
                isAuthenticated = true
                dismiss()
            }
        } catch {
            await MainActor.run {
                alertTitle = "Sign In Failed"
                alertMessage = authManager.errorMessage ?? "Unable to sign in. Please check your credentials."
                showAlert = true
            }
        }
    }
}

#Preview {
    ModernSignInView(authManager: AuthenticationManager(), isAuthenticated: .constant(false))
}
