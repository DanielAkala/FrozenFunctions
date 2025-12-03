import SwiftUI
import CoreData
import FirebaseAuth

struct ModernWelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager  // ✅ Use the shared instance
    @State private var showSignIn = false
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            // Gradient Background
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
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(systemName: "snowflake")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    
                    Text("FrozenFunctions")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Smart Fridge Management")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Create Account Button
                    Button(action: { showSignUp = true }) {
                        Text("Create Account")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Styles.Colors.mainColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .cornerRadius(16)
                    }
                    
                    // Sign In Button
                    Button(action: { showSignIn = true }) {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    // Google Sign In
                    Button(action: {
                        Task { await handleGoogleSignIn() }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.title3)
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(authManager.isLoading)
                    
                    // Guest Mode
                    Button(action: {
                        Task { await handleGuestMode() }
                    }) {
                        Text("Continue as Guest")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            ModernSignInView(authManager: authManager, isAuthenticated: .constant(false))
        }
        .fullScreenCover(isPresented: $showSignUp) {
            ModernSignUpFlow(authManager: authManager, isAuthenticated: .constant(false))
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await authManager.signInWithGoogle()
        } catch {
            print("❌ Google sign in failed: \(error)")
        }
    }
    
    private func handleGuestMode() async {
        do {
            try await authManager.signInAnonymously()
        } catch {
            print("❌ Guest mode failed: \(error)")
        }
    }
}

#Preview {
    ModernWelcomeView()
        .environmentObject(AuthenticationManager())
}
