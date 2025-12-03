import SwiftUI
import CoreData
import FirebaseAuth

struct ModernForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
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
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 8)
                        
                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Enter your email and we'll send you a link to reset your password")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
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
                        
                        Button(action: { Task { await sendPasswordReset() } }) {
                            Group {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(Styles.Colors.mainColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .cornerRadius(16)
                        }
                        .disabled(authManager.isLoading || email.isEmpty || !isValidEmail(email))
                        .opacity((email.isEmpty || !isValidEmail(email)) ? 0.5 : 1.0)
                        .padding(.top, 8)
                        
                        Button(action: { dismiss() }) {
                            Text("Back to Sign In")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendPasswordReset() async {
        do {
            try await authManager.sendPasswordReset(to: email)
            await MainActor.run {
                alertTitle = "Check Your Email ✉️"
                alertMessage = "We've sent password reset instructions to \(email). Please check your inbox (and spam/junk folder) and follow the link to reset your password."
                isSuccess = true
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "Failed to send password reset email. Please check your email address and try again."
                showAlert = true
            }
        }
    }
}

#Preview {
    ModernForgotPasswordView(authManager: AuthenticationManager())
}
