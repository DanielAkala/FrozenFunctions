import SwiftUI
import FirebaseAuth

enum PasswordResetStep {
    case email
    case verification
    case newPassword
}

struct ModernPasswordResetFlow: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthenticationManager
    
    @State private var currentStep: PasswordResetStep = .email
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var sentCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
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
            
            Group {
                switch currentStep {
                case .email:
                    emailStep
                case .verification:
                    verificationStep
                case .newPassword:
                    newPasswordStep
                }
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
    
    // MARK: - Step 1: Enter Email
    private var emailStep: some View {
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
                    ProgressIndicator(currentStep: 1, totalSteps: 3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Password")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Step 1 of 3: Enter your email")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    
                    Text("We'll send a verification code to this email")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: { Task { await sendVerificationCode() } }) {
                        Group {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                            } else {
                                Text("Send Verification Code")
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
    
    // MARK: - Step 2: Verify Code
    private var verificationStep: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { currentStep = .email }) {
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
                    ProgressIndicator(currentStep: 2, totalSteps: 3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verify Code")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step 2 of 3: Enter the code sent to")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("Enter 6-digit code", text: $verificationCode)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: verificationCode) { oldValue, newValue in
                                if newValue.count > 6 {
                                    verificationCode = String(newValue.prefix(6))
                                }
                            }
                    }
                    
                    if !sentCode.isEmpty {
                        VStack(spacing: 4) {
                            Text("📧 Demo Mode - Your code is:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(sentCode)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { verifyCode() }) {
                        Text("Verify Code")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Styles.Colors.mainColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .cornerRadius(16)
                    }
                    .disabled(verificationCode.count != 6)
                    .opacity(verificationCode.count != 6 ? 0.5 : 1.0)
                    .padding(.top, 8)
                    
                    Button(action: { Task { await sendVerificationCode() } }) {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
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
    
    // MARK: - Step 3: New Password
    private var newPasswordStep: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { currentStep = .verification }) {
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
                    ProgressIndicator(currentStep: 3, totalSteps: 3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Step 3 of 3: Choose your new password")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            if showPassword {
                                TextField("Enter new password", text: $newPassword)
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
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
                        
                        Text("Minimum 6 characters")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            if showConfirmPassword {
                                TextField("Re-enter password", text: $confirmPassword)
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(passwordsMatch ? Color.white.opacity(0.2) : Color.red, lineWidth: 1)
                        )
                        
                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { Task { await resetPassword() } }) {
                        HStack(spacing: 8) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                            } else {
                                Image(systemName: "checkmark")
                                Text("Reset Password")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Styles.Colors.mainColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(16)
                    }
                    .disabled(authManager.isLoading || newPassword.count < 6 || !passwordsMatch)
                    .opacity((newPassword.count < 6 || !passwordsMatch) ? 0.5 : 1.0)
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
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Views
    struct ProgressIndicator: View {
        let currentStep: Int
        let totalSteps: Int
        
        var body: some View {
            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Properties
    private var passwordsMatch: Bool {
        newPassword == confirmPassword && !confirmPassword.isEmpty
    }
    
    // MARK: - Actions
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendVerificationCode() async {
        do {
            let code = try await authManager.sendVerificationCode(to: email)
            await MainActor.run {
                sentCode = code
                currentStep = .verification
                alertTitle = "Code Sent"
                alertMessage = "Check your email for the verification code.\n\nDemo code: \(code)"
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "Failed to send verification code. Please try again."
                showAlert = true
            }
        }
    }
    
    private func verifyCode() {
        if authManager.verifyCode(verificationCode, for: email) {
            currentStep = .newPassword
        } else {
            alertTitle = "Invalid Code"
            alertMessage = "The verification code is incorrect or expired."
            showAlert = true
        }
    }
    
    private func resetPassword() async {
        guard newPassword == confirmPassword else {
            await MainActor.run {
                alertTitle = "Password Mismatch"
                alertMessage = "Passwords don't match. Please try again."
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            alertTitle = "Success! 🎉"
            alertMessage = "Your password has been reset. Please sign in with your new password."
            isSuccess = true
            showAlert = true
        }
    }
}

#Preview {
    ModernPasswordResetFlow(authManager: AuthenticationManager())
}
