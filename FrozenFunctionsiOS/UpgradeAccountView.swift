import SwiftUI

struct UpgradeAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            Text("Save Your Data Forever")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            Text("Create an account to:")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.thirdColor)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                BenefitRow(icon: "icloud.fill", text: "Sync across devices")
                                BenefitRow(icon: "checkmark.shield.fill", text: "Keep your data safe")
                                BenefitRow(icon: "arrow.clockwise", text: "Never lose your fridge items")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        Divider()
                            .background(Styles.Colors.iconColor)
                            .padding(.horizontal)
                        VStack(spacing: 16) {
                            Text("Create Your Account")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(Styles.CustomTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(Styles.CustomTextFieldStyle())
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(Styles.CustomTextFieldStyle())
                        }
                        .padding(.horizontal, 32)

                        Button(action: {
                            Task {
                                await createAccount()
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                                } else {
                                    Text("Create Account & Save Data")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Styles.Colors.accentColor)
                            .foregroundColor(Styles.Colors.mainColor)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || !isValidInput())
                        .padding(.horizontal, 32)

                        HStack {
                            Rectangle()
                                .fill(Styles.Colors.iconColor)
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(Styles.Colors.iconColor)
                            Rectangle()
                                .fill(Styles.Colors.iconColor)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)

                        Button(action: {
                            Task {
                                await linkWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                Text("Continue with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Styles.Colors.secondaryColor)
                            .foregroundColor(Styles.Colors.accentColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Styles.Colors.iconColor, lineWidth: 1)
                            )
                        }
                        .disabled(authManager.isLoading)
                        .padding(.horizontal, 32)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundColor(Styles.Colors.iconColor)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Upgrade Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Styles.Colors.accentColor)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    }

    private func isValidInput() -> Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }

    private func createAccount() async {
        guard password == confirmPassword else {
            await MainActor.run {
                alertTitle = "Password Mismatch"
                alertMessage = "Passwords don't match. Please try again."
                showAlert = true
            }
            return
        }
        
        guard password.count >= 6 else {
            await MainActor.run {
                alertTitle = "Weak Password"
                alertMessage = "Password must be at least 6 characters long."
                showAlert = true
            }
            return
        }
        
        do {
            try await authManager.linkAnonymousAccount(email: email, password: password)
            await MainActor.run {
                alertTitle = "Success! 🎉"
                alertMessage = "Your account has been created and your data is now saved!"
                isSuccess = true
                showAlert = true
            }
        } catch {
            print("❌ Account creation failed: \(error)")
        }
    }
    
    private func linkWithGoogle() async {
        do {
            try await authManager.linkAnonymousAccountWithGoogle()
            await MainActor.run {
                alertTitle = "Success! 🎉"
                alertMessage = "Your account has been linked and your data is now saved!"
                isSuccess = true
                showAlert = true
            }
        } catch {
            print("❌ Google linking failed: \(error)")
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Styles.Colors.accentColor)
                .frame(width: 30)
            
            Text(text)
                .foregroundColor(Styles.Colors.thirdColor)
            
            Spacer()
        }
    }
}

#Preview {
    UpgradeAccountView()
        .environmentObject(AuthenticationManager())
}
