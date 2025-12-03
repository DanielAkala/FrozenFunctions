//import SwiftUI
//import CoreData
//import FirebaseAuth
//import UserNotifications
//
//enum SignUpStep {
//    case email
//    case verification
//    case password
//    case profile
//}
//
//struct ModernSignUpFlow: View {
//    @Environment(\.dismiss) private var dismiss
//    @ObservedObject var authManager: AuthenticationManager
//    @Binding var isAuthenticated: Bool
//    
//    @State private var currentStep: SignUpStep = .email
//    @State private var email = ""
//    @State private var verificationCode = ""
//    @State private var sentCode = ""
//    @State private var password = ""
//    @State private var confirmPassword = ""
//    @State private var username = ""
//    @State private var fridgeName = ""
//    @State private var onlineMode = true
//    @State private var notifications = true
//    @State private var showPassword = false
//    @State private var showConfirmPassword = false
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//    @State private var isSendingCode = false
//    
//    var body: some View {
//        ZStack {
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color(red: 0.076, green: 0.153, blue: 0.278),
//                    Color(red: 0.1, green: 0.2, blue: 0.4),
//                    Color(red: 0.076, green: 0.153, blue: 0.278)
//                ]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//            
//            Group {
//                switch currentStep {
//                case .email:
//                    emailStep
//                case .verification:
//                    verificationStep
//                case .password:
//                    passwordStep
//                case .profile:
//                    profileStep
//                }
//            }
//        }
//        .alert("Alert", isPresented: $showAlert) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text(alertMessage)
//        }
//    }
//    
//    // MARK: - Step 1: Email
//    private var emailStep: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                HStack {
//                    Button(action: { dismiss() }) {
//                        HStack(spacing: 8) {
//                            Image(systemName: "chevron.left")
//                            Text("Back")
//                        }
//                        .foregroundColor(.white.opacity(0.7))
//                    }
//                    Spacer()
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 16)
//                .padding(.bottom, 40)
//                
//                VStack(spacing: 24) {
//                    ProgressIndicator(currentStep: 1, totalSteps: 4)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Create Account")
//                            .font(.system(size: 32, weight: .bold))
//                            .foregroundColor(.white)
//                        
//                        Text("Step 1 of 4: Enter your email")
//                            .font(.subheadline)
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.bottom, 8)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Email Address")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white.opacity(0.9))
//                        
//                        HStack(spacing: 12) {
//                            Image(systemName: "envelope.fill")
//                                .foregroundColor(.white.opacity(0.5))
//                                .frame(width: 20)
//                            
//                            TextField("name@example.com", text: $email)
//                                .textInputAutocapitalization(.never)
//                                .keyboardType(.emailAddress)
//                                .autocorrectionDisabled()
//                                .foregroundColor(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                        )
//                    }
//                    
//                    Text("We'll send a verification code to confirm your email")
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.5))
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    Button(action: { Task { await sendVerificationCode() } }) {
//                        Group {
//                            if isSendingCode {
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
//                            } else {
//                                Text("Send Verification Code")
//                                    .font(.system(size: 18, weight: .semibold))
//                            }
//                        }
//                        .foregroundColor(Styles.Colors.mainColor)
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 56)
//                        .background(.white)
//                        .cornerRadius(16)
//                    }
//                    .disabled(email.isEmpty || !isValidEmail(email))
//                    .opacity((email.isEmpty || !isValidEmail(email)) ? 0.5 : 1.0)
//                    .padding(.top, 8)
//                }
//                .padding(28)
//                .background(Color.white.opacity(0.05))
//                .cornerRadius(24)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 24)
//                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                )
//                .padding(.horizontal, 24)
//                
//                HStack(spacing: 4) {
//                    Text("Already have an account?")
//                        .foregroundColor(.white.opacity(0.7))
//                    Button(action: { dismiss() }) {
//                        Text("Sign In")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                    }
//                }
//                .font(.subheadline)
//                .padding(.top, 24)
//            }
//            .padding(.bottom, 40)
//        }
//    }
//    
//    // MARK: - Step 2: Verification Code
//    private var verificationStep: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                HStack {
//                    Button(action: { currentStep = .email }) {
//                        HStack(spacing: 8) {
//                            Image(systemName: "chevron.left")
//                            Text("Back")
//                        }
//                        .foregroundColor(.white.opacity(0.7))
//                    }
//                    Spacer()
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 16)
//                .padding(.bottom, 40)
//                
//                VStack(spacing: 24) {
//                    ProgressIndicator(currentStep: 2, totalSteps: 4)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Verify Email")
//                            .font(.system(size: 32, weight: .bold))
//                            .foregroundColor(.white)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Step 2 of 4: Enter the code sent to")
//                                .font(.subheadline)
//                                .foregroundColor(.white.opacity(0.7))
//                            Text(email)
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.bottom, 8)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Verification Code")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white.opacity(0.9))
//                        
//                        HStack(spacing: 12) {
//                            Image(systemName: "number")
//                                .foregroundColor(.white.opacity(0.5))
//                                .frame(width: 20)
//                            
//                            TextField("Enter 6-digit code", text: $verificationCode)
//                                .keyboardType(.numberPad)
//                                .foregroundColor(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                        )
//                    }
//                    
//                    Button(action: { Task { await sendVerificationCode() } }) {
//                        Text("Resend Code")
//                            .font(.subheadline)
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                    
//                    Button(action: { verifyCodeAndContinue() }) {
//                        Text("Verify & Continue")
//                            .font(.system(size: 18, weight: .semibold))
//                            .foregroundColor(Styles.Colors.mainColor)
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 56)
//                            .background(.white)
//                            .cornerRadius(16)
//                    }
//                    .disabled(verificationCode.count != 6)
//                    .opacity(verificationCode.count != 6 ? 0.5 : 1.0)
//                    .padding(.top, 8)
//                }
//                .padding(28)
//                .background(Color.white.opacity(0.05))
//                .cornerRadius(24)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 24)
//                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                )
//                .padding(.horizontal, 24)
//            }
//            .padding(.bottom, 40)
//        }
//    }
//    
//    // MARK: - Step 3: Password
//    private var passwordStep: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                backButton(action: { currentStep = .verification })
//                passwordStepContent
//            }
//            .padding(.bottom, 40)
//        }
//    }
//    
//    private var passwordStepContent: some View {
//        VStack(spacing: 24) {
//            ProgressIndicator(currentStep: 3, totalSteps: 4)
//            
//            passwordStepHeader
//            passwordField
//            confirmPasswordField
//            passwordMatchIndicator
//            passwordHint
//            continueToProfileButton
//        }
//        .padding(28)
//        .background(Color.white.opacity(0.05))
//        .cornerRadius(24)
//        .overlay(
//            RoundedRectangle(cornerRadius: 24)
//                .stroke(Color.white.opacity(0.1), lineWidth: 1)
//        )
//        .padding(.horizontal, 24)
//    }
//    
//    private var passwordStepHeader: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Create Password")
//                .font(.system(size: 32, weight: .bold))
//                .foregroundColor(.white)
//            
//            Text("Step 3 of 4: Choose a secure password")
//                .font(.subheadline)
//                .foregroundColor(.white.opacity(0.7))
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.bottom, 8)
//    }
//    
//    private var passwordField: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Password")
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.white.opacity(0.9))
//            
//            HStack(spacing: 12) {
//                Image(systemName: "lock.fill")
//                    .foregroundColor(.white.opacity(0.5))
//                    .frame(width: 20)
//                
//                Group {
//                    if showPassword {
//                        TextField("At least 6 characters", text: $password)
//                    } else {
//                        SecureField("At least 6 characters", text: $password)
//                    }
//                }
//                .foregroundColor(.white)
//                .autocorrectionDisabled()
//                .textInputAutocapitalization(.never)
//                
//                Button(action: { showPassword.toggle() }) {
//                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
//                        .foregroundColor(.white.opacity(0.5))
//                }
//            }
//            .padding(16)
//            .background(Color.white.opacity(0.1))
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
//            )
//        }
//    }
//    
//    private var confirmPasswordField: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Confirm Password")
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.white.opacity(0.9))
//            
//            HStack(spacing: 12) {
//                Image(systemName: "lock.fill")
//                    .foregroundColor(.white.opacity(0.5))
//                    .frame(width: 20)
//                
//                Group {
//                    if showConfirmPassword {
//                        TextField("Re-enter password", text: $confirmPassword)
//                    } else {
//                        SecureField("Re-enter password", text: $confirmPassword)
//                    }
//                }
//                .foregroundColor(.white)
//                .autocorrectionDisabled()
//                .textInputAutocapitalization(.never)
//                
//                Button(action: { showConfirmPassword.toggle() }) {
//                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
//                        .foregroundColor(.white.opacity(0.5))
//                }
//            }
//            .padding(16)
//            .background(Color.white.opacity(0.1))
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(passwordsMatch ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
//            )
//        }
//    }
//    
//    @ViewBuilder
//    private var passwordMatchIndicator: some View {
//        if passwordsMatch {
//            HStack(spacing: 8) {
//                Image(systemName: "checkmark.circle.fill")
//                    .foregroundColor(.green)
//                Text("Passwords match!")
//                    .font(.caption)
//                    .foregroundColor(.green)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//    }
//    
//    private var passwordHint: some View {
//        Text("Password must be at least 6 characters long")
//            .font(.caption)
//            .foregroundColor(.white.opacity(0.5))
//            .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    
//    private var continueToProfileButton: some View {
//        Button(action: { currentStep = .profile }) {
//            Text("Continue")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(Styles.Colors.mainColor)
//                .frame(maxWidth: .infinity)
//                .frame(height: 56)
//                .background(.white)
//                .cornerRadius(16)
//        }
//        .disabled(!passwordsMatch || password.count < 6)
//        .opacity((!passwordsMatch || password.count < 6) ? 0.5 : 1.0)
//        .padding(.top, 8)
//    }
//    
//    private func backButton(action: @escaping () -> Void) -> some View {
//        HStack {
//            Button(action: action) {
//                HStack(spacing: 8) {
//                    Image(systemName: "chevron.left")
//                    Text("Back")
//                }
//                .foregroundColor(.white.opacity(0.7))
//            }
//            Spacer()
//        }
//        .padding(.horizontal, 24)
//        .padding(.top, 16)
//        .padding(.bottom, 40)
//    }
//    
//    // MARK: - Step 4: Profile Setup
//    private var profileStep: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                HStack {
//                    Button(action: { currentStep = .password }) {
//                        HStack(spacing: 8) {
//                            Image(systemName: "chevron.left")
//                            Text("Back")
//                        }
//                        .foregroundColor(.white.opacity(0.7))
//                    }
//                    Spacer()
//                }
//                .padding(.horizontal, 24)
//                .padding(.top, 16)
//                .padding(.bottom, 40)
//                
//                VStack(spacing: 24) {
//                    ProgressIndicator(currentStep: 4, totalSteps: 4)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Setup Profile")
//                            .font(.system(size: 32, weight: .bold))
//                            .foregroundColor(.white)
//                        
//                        Text("Step 4 of 4: Personalize your experience")
//                            .font(.subheadline)
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.bottom, 8)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Username")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white.opacity(0.9))
//                        
//                        HStack(spacing: 12) {
//                            Image(systemName: "person.fill")
//                                .foregroundColor(.white.opacity(0.5))
//                                .frame(width: 20)
//                            
//                            TextField("Choose a username", text: $username)
//                                .textInputAutocapitalization(.words)
//                                .foregroundColor(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                        )
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Fridge Name")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white.opacity(0.9))
//                        
//                        HStack(spacing: 12) {
//                            Image(systemName: "snowflake")
//                                .foregroundColor(.white.opacity(0.5))
//                                .frame(width: 20)
//                            
//                            TextField("My Fridge", text: $fridgeName)
//                                .textInputAutocapitalization(.words)
//                                .foregroundColor(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                        )
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Preferences")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white.opacity(0.9))
//                            .padding(.top, 8)
//                        
//                        HStack {
//                            HStack(spacing: 12) {
//                                Image(systemName: "wifi")
//                                    .foregroundColor(.white.opacity(0.7))
//                                    .frame(width: 20)
//                                Text("Online Mode")
//                                    .foregroundColor(.white)
//                            }
//                            
//                            Spacer()
//                            
//                            Toggle("", isOn: $onlineMode)
//                                .labelsHidden()
//                                .tint(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                        
//                        HStack {
//                            HStack(spacing: 12) {
//                                Image(systemName: "bell.fill")
//                                    .foregroundColor(.white.opacity(0.7))
//                                    .frame(width: 20)
//                                Text("Notifications")
//                                    .foregroundColor(.white)
//                            }
//                            
//                            Spacer()
//                            
//                            Toggle("", isOn: $notifications)
//                                .labelsHidden()
//                                .tint(.white)
//                        }
//                        .padding(16)
//                        .background(Color.white.opacity(0.1))
//                        .cornerRadius(12)
//                    }
//                    
//                    Button(action: { Task { await completeSignUp() } }) {
//                        HStack(spacing: 8) {
//                            if authManager.isLoading {
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
//                            } else {
//                                Image(systemName: "checkmark")
//                                Text("Complete Setup")
//                            }
//                        }
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(Styles.Colors.mainColor)
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 56)
//                        .background(.white)
//                        .cornerRadius(16)
//                    }
//                    .disabled(authManager.isLoading || username.isEmpty || fridgeName.isEmpty)
//                    .opacity((username.isEmpty || fridgeName.isEmpty) ? 0.5 : 1.0)
//                    .padding(.top, 8)
//                }
//                .padding(28)
//                .background(Color.white.opacity(0.05))
//                .cornerRadius(24)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 24)
//                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                )
//                .padding(.horizontal, 24)
//            }
//            .padding(.bottom, 40)
//        }
//    }
//    
//    // MARK: - Helper Views
//    struct ProgressIndicator: View {
//        let currentStep: Int
//        let totalSteps: Int
//        
//        var body: some View {
//            HStack(spacing: 8) {
//                ForEach(1...totalSteps, id: \.self) { step in
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
//                        .frame(height: 4)
//                }
//            }
//            .padding(.bottom, 16)
//        }
//    }
//    
//    // MARK: - Helper Properties
//    private var passwordsMatch: Bool {
//        password == confirmPassword && !confirmPassword.isEmpty
//    }
//    
//    // MARK: - Actions
//    private func isValidEmail(_ email: String) -> Bool {
//        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
//        return emailPredicate.evaluate(with: email)
//    }
//    
//    private func completeSignUp() async {
//        do {
//            // Create Firebase account (this sends verification email automatically)
//            try await authManager.signUp(email: email, password: password)
//            
//            // ✅ Wait a moment for auth state to settle and default profile to be created
//            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
//            
//            // Now save the user's custom profile data (will update the default profile)
//            await saveProfileData()
//            
//            UserDefaults.standard.set(onlineMode, forKey: "onlineMode")
//            UserDefaults.standard.set(notifications, forKey: "notificationsEnabled")
//            
//            if notifications {
//                await requestNotificationPermission()
//            }
//            
//            await MainActor.run {
//                isAuthenticated = true
//                alertMessage = "Account created! Please check your email to verify your account."
//                showAlert = true
//            }
//            
//            // Dismiss after showing alert
//            try? await Task.sleep(nanoseconds: 2_000_000_000)
//            await MainActor.run {
//                dismiss()
//            }
//        } catch {
//            await MainActor.run {
//                alertMessage = authManager.errorMessage ?? "Unable to create account. Please try again."
//                showAlert = true
//            }
//        }
//    }
//    
//    private func requestNotificationPermission() async {
//        let center = UNUserNotificationCenter.current()
//        do {
//            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
//            print(granted ? "✅ Notifications authorized" : "⚠️ Notifications denied")
//        } catch {
//            print("❌ Notification permission error: \(error)")
//        }
//    }
//    
//    private func saveProfileData() async {
//        let context = PersistenceController.shared.container.viewContext
//        
//        await MainActor.run {
//            // ✅ Check if profile already exists
//            let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
//            
//            do {
//                let existingProfiles = try context.fetch(fetchRequest)
//                let profile: Profile
//                
//                if let existingProfile = existingProfiles.first {
//                    // Update existing profile
//                    profile = existingProfile
//                    print("📝 Updating existing profile during sign up")
//                } else {
//                    // Create new profile
//                    profile = Profile(context: context)
//                    print("📝 Creating new profile during sign up")
//                }
//                
//                // Set the values
//                profile.userName = username
//                profile.fridgeName = fridgeName
//                profile.diet = "None"
//                
//                try context.save()
//                print("✅ Profile saved: userName='\(username)', fridgeName='\(fridgeName)'")
//                
//                // Verify the save
//                let verifyProfiles = try context.fetch(fetchRequest)
//                print("✅ Verification: \(verifyProfiles.count) profile(s) in database")
//                if let savedProfile = verifyProfiles.first {
//                    print("✅ Saved profile data: userName='\(savedProfile.userName ?? "nil")', fridgeName='\(savedProfile.fridgeName ?? "nil")'")
//                }
//                
//                // ✅ Sync to Firestore
//                Task {
//                    do {
//                        try await FirestoreService.shared.syncProfileToCloud(profile, context: context)
//                        print("✅ Profile synced to Firestore")
//                    } catch {
//                        print("⚠️ Failed to sync to cloud: \(error)")
//                    }
//                }
//            } catch {
//                print("❌ Failed to save profile: \(error)")
//            }
//        }
//    }
//    
//    // MARK: - Verification Functions
//    private func sendVerificationCode() async {
//        isSendingCode = true
//        defer { isSendingCode = false }
//        
//        // Response structure from Firebase function
//        struct VerificationResponse: Codable {
//            let success: Bool
//            let code: String
//            let message: String
//        }
//        
//        // Call your Firebase function
//        guard let url = URL(string: "https://sendverificationcode-oq5ojojfyq-uc.a.run.app") else {
//            await MainActor.run {
//                alertMessage = "Configuration error. Please try again."
//                showAlert = true
//            }
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: String] = ["email": email]
//        request.httpBody = try? JSONEncoder().encode(body)
//        
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                throw URLError(.badServerResponse)
//            }
//            
//            print("📧 Email verification response status: \(httpResponse.statusCode)")
//            
//            if httpResponse.statusCode != 200 {
//                if let errorText = String(data: data, encoding: .utf8) {
//                    print("❌ Error response: \(errorText)")
//                }
//                throw URLError(.badServerResponse)
//            }
//            
//            // Parse the response with correct structure
//            let result = try JSONDecoder().decode(VerificationResponse.self, from: data)
//            print("✅ Got verification code: \(result.code)")
//            
//            await MainActor.run {
//                sentCode = result.code
//                currentStep = .verification
//                print("✅ Moving to verification step")
//            }
//            
//        } catch {
//            print("❌ Network error: \(error)")
//            await MainActor.run {
//                alertMessage = "Failed to send code. Please check your email and try again."
//                showAlert = true
//            }
//        }
//    }
//    
//    private func verifyCodeAndContinue() {
//        if verificationCode == sentCode {
//            currentStep = .password
//        } else {
//            alertMessage = "Invalid verification code. Please try again."
//            showAlert = true
//        }
//    }
//}
//
//#Preview {
//    ModernSignUpFlow(authManager: AuthenticationManager(), isAuthenticated: .constant(false))
//}

import SwiftUI
import CoreData
import FirebaseAuth
import UserNotifications

enum SignUpStep {
    case email
    case verification
    case password
    case profile
}

struct ModernSignUpFlow: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthenticationManager
    @Binding var isAuthenticated: Bool
    
    @State private var currentStep: SignUpStep = .email
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var sentCode = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var fridgeName = ""
    @State private var onlineMode = true
    @State private var notifications = true
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSendingCode = false
    
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
                case .password:
                    passwordStep
                case .profile:
                    profileStep
                }
            }
        }
        .alert("Alert", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Step 1: Email
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
                    ProgressIndicator(currentStep: 1, totalSteps: 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Step 1 of 4: Enter your email")
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
                    
                    Text("We'll send a verification code to confirm your email")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: { Task { await sendVerificationCode() } }) {
                        Group {
                            if isSendingCode {
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
                    .disabled(email.isEmpty || !isValidEmail(email))
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
                
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.white.opacity(0.7))
                    Button(action: { dismiss() }) {
                        Text("Sign In")
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
    
    // MARK: - Step 2: Verification Code
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
                    ProgressIndicator(currentStep: 2, totalSteps: 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verify Email")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step 2 of 4: Enter the code sent to")
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
                        
                        HStack(spacing: 12) {
                            Image(systemName: "number")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            TextField("Enter 6-digit code", text: $verificationCode)
                                .keyboardType(.numberPad)
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
                    
                    Button(action: { Task { await sendVerificationCode() } }) {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Button(action: { verifyCodeAndContinue() }) {
                        Text("Verify & Continue")
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
    
    // MARK: - Step 3: Password
    private var passwordStep: some View {
        ScrollView {
            VStack(spacing: 0) {
                backButton(action: { currentStep = .verification })
                passwordStepContent
            }
            .padding(.bottom, 40)
        }
    }
    
    private var passwordStepContent: some View {
        VStack(spacing: 24) {
            ProgressIndicator(currentStep: 3, totalSteps: 4)
            
            passwordStepHeader
            passwordField
            confirmPasswordField
            passwordMatchIndicator
            passwordHint
            continueToProfileButton
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
    
    private var passwordStepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Password")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Step 3 of 4: Choose a secure password")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
                
                Group {
                    if showPassword {
                        TextField("At least 6 characters", text: $password)
                    } else {
                        SecureField("At least 6 characters", text: $password)
                    }
                }
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                
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
    }
    
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm Password")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
                
                Group {
                    if showConfirmPassword {
                        TextField("Re-enter password", text: $confirmPassword)
                    } else {
                        SecureField("Re-enter password", text: $confirmPassword)
                    }
                }
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                
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
                    .stroke(passwordsMatch ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var passwordMatchIndicator: some View {
        if passwordsMatch {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Passwords match!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var passwordHint: some View {
        Text("Password must be at least 6 characters long")
            .font(.caption)
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var continueToProfileButton: some View {
        Button(action: { currentStep = .profile }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Styles.Colors.mainColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .cornerRadius(16)
        }
        .disabled(!passwordsMatch || password.count < 6)
        .opacity((!passwordsMatch || password.count < 6) ? 0.5 : 1.0)
        .padding(.top, 8)
    }
    
    private func backButton(action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) {
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
    }
    
    // MARK: - Step 4: Profile Setup
    private var profileStep: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { currentStep = .password }) {
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
                    ProgressIndicator(currentStep: 4, totalSteps: 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Setup Profile")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Step 4 of 4: Personalize your experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            TextField("Choose a username", text: $username)
                                .textInputAutocapitalization(.words)
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
                        Text("Fridge Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "snowflake")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            TextField("My Fridge", text: $fridgeName)
                                .textInputAutocapitalization(.words)
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 8)
                        
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "wifi")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                Text("Online Mode")
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $onlineMode)
                                .labelsHidden()
                                .tint(.white)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                Text("Notifications")
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $notifications)
                                .labelsHidden()
                                .tint(.white)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { Task { await completeSignUp() } }) {
                        HStack(spacing: 8) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.mainColor))
                            } else {
                                Image(systemName: "checkmark")
                                Text("Complete Setup")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Styles.Colors.mainColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(16)
                    }
                    .disabled(authManager.isLoading || username.isEmpty || fridgeName.isEmpty)
                    .opacity((username.isEmpty || fridgeName.isEmpty) ? 0.5 : 1.0)
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
        password == confirmPassword && !confirmPassword.isEmpty
    }
    
    // MARK: - Actions
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func completeSignUp() async {
        do {
            // Create Firebase account (this sends verification email automatically)
            try await authManager.signUp(email: email, password: password)
            
            // ✅ Wait a moment for auth state to settle and default profile to be created
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Now save the user's custom profile data (will update the default profile)
            await saveProfileData()
            
            // ✅ Save preferences with user-specific keys
            if let userId = authManager.user?.uid {
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode_\(userId)")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled_\(userId)")
                print("✅ User-specific preferences saved for \(userId)")
            } else {
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled")
                print("⚠️ Saved global preferences (no user ID)")
            }
            
            // ✅ Notify ContentView that settings changed
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
            
            if notifications {
                await requestNotificationPermission()
            }
            
            await MainActor.run {
                isAuthenticated = true
                alertMessage = "Account created! Please check your email to verify your account."
                showAlert = true
            }
            
            // Dismiss after showing alert
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                alertMessage = authManager.errorMessage ?? "Unable to create account. Please try again."
                showAlert = true
            }
        }
    }
    
    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "✅ Notifications authorized" : "⚠️ Notifications denied")
        } catch {
            print("❌ Notification permission error: \(error)")
        }
    }
    
    private func saveProfileData() async {
        let context = PersistenceController.shared.container.viewContext
        
        await MainActor.run {
            // ✅ Check if profile already exists
            let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
            
            do {
                let existingProfiles = try context.fetch(fetchRequest)
                let profile: Profile
                
                if let existingProfile = existingProfiles.first {
                    // Update existing profile
                    profile = existingProfile
                    print("📝 Updating existing profile during sign up")
                } else {
                    // Create new profile
                    profile = Profile(context: context)
                    print("📝 Creating new profile during sign up")
                }
                
                // Set the values
                profile.userName = username
                profile.fridgeName = fridgeName
                profile.diet = "None"
                
                try context.save()
                print("✅ Profile saved: userName='\(username)', fridgeName='\(fridgeName)'")
                
                // Verify the save
                let verifyProfiles = try context.fetch(fetchRequest)
                print("✅ Verification: \(verifyProfiles.count) profile(s) in database")
                if let savedProfile = verifyProfiles.first {
                    print("✅ Saved profile data: userName='\(savedProfile.userName ?? "nil")', fridgeName='\(savedProfile.fridgeName ?? "nil")'")
                }
                
                // ✅ Sync to Firestore
                Task {
                    do {
                        try await FirestoreService.shared.syncProfileToCloud(profile, context: context)
                        print("✅ Profile synced to Firestore")
                    } catch {
                        print("⚠️ Failed to sync to cloud: \(error)")
                    }
                }
            } catch {
                print("❌ Failed to save profile: \(error)")
            }
        }
    }
    
    // MARK: - Verification Functions
    private func sendVerificationCode() async {
        isSendingCode = true
        defer { isSendingCode = false }
        
        // Response structure from Firebase function
        struct VerificationResponse: Codable {
            let success: Bool
            let code: String
            let message: String
        }
        
        // Call your Firebase function
        guard let url = URL(string: "https://sendverificationcode-oq5ojojfyq-uc.a.run.app") else {
            await MainActor.run {
                alertMessage = "Configuration error. Please try again."
                showAlert = true
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("📧 Email verification response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorText)")
                }
                throw URLError(.badServerResponse)
            }
            
            // Parse the response with correct structure
            let result = try JSONDecoder().decode(VerificationResponse.self, from: data)
            print("✅ Got verification code: \(result.code)")
            
            await MainActor.run {
                sentCode = result.code
                currentStep = .verification
                print("✅ Moving to verification step")
            }
            
        } catch {
            print("❌ Network error: \(error)")
            await MainActor.run {
                alertMessage = "Failed to send code. Please check your email and try again."
                showAlert = true
            }
        }
    }
    
    private func verifyCodeAndContinue() {
        if verificationCode == sentCode {
            currentStep = .password
        } else {
            alertMessage = "Invalid verification code. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    ModernSignUpFlow(authManager: AuthenticationManager(), isAuthenticated: .constant(false))
}
