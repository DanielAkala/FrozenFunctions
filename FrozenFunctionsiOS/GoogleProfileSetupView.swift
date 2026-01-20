import SwiftUI
import UserNotifications
import FirebaseAuth

struct GoogleProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var username = ""
    @State private var fridgeName = ""
    @State private var onlineMode = true
    @State private var notifications = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Text("Welcome!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Let's personalize your experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Setup Your Profile")
                                .font(.headline)
                                .foregroundColor(.white)
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
                        }
                        Button(action: { Task { await completeSetup() } }) {
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
        .alert("Alert", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let displayName = authManager.user?.displayName {
                username = displayName
            }
        }
    }
    
    private func completeSetup() async {
        do {
            try await authManager.completeProfileSetup(
                username: username,
                fridgeName: fridgeName,
                notifications: notifications,
                onlineMode: onlineMode
            )
            if notifications {
                await requestNotificationPermission()
            }
            
            print("✅ Profile setup completed")
        } catch {
            await MainActor.run {
                alertMessage = "Failed to complete setup. Please try again."
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
}

#Preview {
    GoogleProfileSetupView()
        .environmentObject(AuthenticationManager())
}
