//import SwiftUI
//import UserNotifications
//import FirebaseAuth
//
//struct CustomToggleStyle: ToggleStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack {
//            configuration.label
//            
//            Spacer()
//            
//            RoundedRectangle(cornerRadius: 16)
//                .fill(configuration.isOn ? Styles.Colors.mainColor : Styles.Colors.iconColor)
//                .frame(width: 51, height: 31)
//                .overlay(
//                    Circle()
//                        .foregroundColor(Styles.Colors.accentColor)
//                        .padding(2)
//                        .offset(x: configuration.isOn ? 10 : -10)
//                )
//                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
//                .onTapGesture {
//                    configuration.isOn.toggle()
//                }
//        }
//    }
//}
//
//struct UpdatedSettingsView: View {
//    @Environment(\.dismiss) private var dismiss
//    @EnvironmentObject var authManager: AuthenticationManager
//    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
//    @AppStorage("onlineMode") private var onlineMode = true
//    
//    @State private var showingNotificationAlert = false
//    @State private var showingPasswordReset = false
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                Styles.Colors.mainColor.ignoresSafeArea()
//                
//                Form {
//                    // Account Section (for signed-in users)
//                    if let user = authManager.user, !authManager.isAnonymous {
//                        Section {
//                            // Email Display
//                            if let email = user.email {
//                                HStack {
//                                    Image(systemName: "envelope.fill")
//                                        .foregroundColor(Styles.Colors.accentColor)
//                                        .font(.title3)
//                                    
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Email")
//                                            .font(.headline)
//                                            .foregroundColor(Styles.Colors.accentColor)
//                                        
//                                        Text(email)
//                                            .font(.caption)
//                                            .foregroundColor(Styles.Colors.thirdColor)
//                                    }
//                                }
//                                .listRowBackground(Styles.Colors.secondaryColor)
//                            }
//                            
//                            // Reset Password Button
//                            Button(action: {
//                                showingPasswordReset = true
//                            }) {
//                                HStack {
//                                    Image(systemName: "lock.rotation")
//                                        .foregroundColor(Styles.Colors.accentColor)
//                                        .font(.title3)
//                                    
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Reset Password")
//                                            .font(.headline)
//                                            .foregroundColor(Styles.Colors.accentColor)
//                                        
//                                        Text("Change your account password")
//                                            .font(.caption)
//                                            .foregroundColor(Styles.Colors.thirdColor)
//                                    }
//                                    
//                                    Spacer()
//                                    
//                                    Image(systemName: "chevron.right")
//                                        .foregroundColor(Styles.Colors.iconColor)
//                                        .font(.caption)
//                                }
//                            }
//                            .listRowBackground(Styles.Colors.secondaryColor)
//                        } header: {
//                            Label("Account", systemImage: "person.circle")
//                                .foregroundColor(Styles.Colors.thirdColor)
//                        }
//                    }
//                    
//                    // Notifications Section
//                    Section {
//                        Toggle(isOn: $notificationsEnabled) {
//                            HStack {
//                                Image(systemName: "bell.fill")
//                                    .foregroundColor(notificationsEnabled ? Styles.Colors.accentColor : Styles.Colors.iconColor)
//                                    .font(.title3)
//                                
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("Notifications")
//                                        .font(.headline)
//                                        .foregroundColor(Styles.Colors.accentColor)
//                                    
//                                    Text("Get alerts when items expire")
//                                        .font(.caption)
//                                        .foregroundColor(Styles.Colors.thirdColor)
//                                }
//                            }
//                        }
//                        .toggleStyle(CustomToggleStyle())
//                        .listRowBackground(Styles.Colors.secondaryColor)
//                        .onChange(of: notificationsEnabled) { oldValue, newValue in
//                            handleNotificationToggle(enabled: newValue)
//                        }
//                    } header: {
//                        Label("Notifications", systemImage: "app.badge")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                    } footer: {
//                        Text("Enable to receive expiration reminders")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                            .font(.caption)
//                    }
//                    
//                    // Online Mode Section
//                    Section {
//                        Toggle(isOn: $onlineMode) {
//                            HStack {
//                                Image(systemName: onlineMode ? "wifi" : "wifi.slash")
//                                    .foregroundColor(onlineMode ? Styles.Colors.accentColor : Styles.Colors.iconColor)
//                                    .font(.title3)
//                                
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("Online Mode")
//                                        .font(.headline)
//                                        .foregroundColor(Styles.Colors.accentColor)
//                                    
//                                    Text(onlineMode ? "AI recipe generation enabled" : "Using offline mode")
//                                        .font(.caption)
//                                        .foregroundColor(Styles.Colors.thirdColor)
//                                }
//                            }
//                        }
//                        .toggleStyle(CustomToggleStyle())
//                        .listRowBackground(Styles.Colors.secondaryColor)
//                    } header: {
//                        Label("Recipe Features", systemImage: "network")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                    } footer: {
//                        Text("Online mode enables AI-powered recipe generation. Turn off to use the app without internet features.")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                            .font(.caption)
//                    }
//                    
//                    // App Info Section
//                    Section {
//                        HStack {
//                            Label("Version", systemImage: "info.circle.fill")
//                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
//                            
//                            Spacer()
//                            
//                            Text("1.0.0")
//                                .foregroundColor(Styles.Colors.thirdColor)
//                        }
//                        .listRowBackground(Styles.Colors.secondaryColor)
//                    } header: {
//                        Label("About", systemImage: "questionmark.circle")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                    }
//                }
//                .scrollContentBackground(.hidden)
//                .colorScheme(.dark)
//            }
//            .navigationTitle("Settings")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                    .foregroundColor(Styles.Colors.accentColor)
//                }
//            }
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
//            .toolbarColorScheme(.dark, for: .navigationBar)
//            .alert("Notification Permission Required", isPresented: $showingNotificationAlert) {
//                Button("Open Settings") {
//                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                        UIApplication.shared.open(url)
//                    }
//                }
//                Button("Cancel", role: .cancel) {
//                    notificationsEnabled = false
//                }
//            } message: {
//                Text("Please enable notifications in your device settings to receive expiration alerts.")
//            }
//            .fullScreenCover(isPresented: $showingPasswordReset) {
//                ModernForgotPasswordView(authManager: authManager)
//            }
//        }
//    }
//    
//    private func handleNotificationToggle(enabled: Bool) {
//        if enabled {
//            UNUserNotificationCenter.current().getNotificationSettings { settings in
//                DispatchQueue.main.async {
//                    if settings.authorizationStatus == .denied {
//                        showingNotificationAlert = true
//                    } else if settings.authorizationStatus == .notDetermined {
//                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//                            DispatchQueue.main.async {
//                                if !granted {
//                                    notificationsEnabled = false
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    UpdatedSettingsView()
//        .environmentObject(AuthenticationManager())
//}

import SwiftUI
import UserNotifications
import FirebaseAuth

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Styles.Colors.mainColor : Styles.Colors.iconColor)
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .foregroundColor(Styles.Colors.accentColor)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct UpdatedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var notificationsEnabled = true  // ✅ Changed from @AppStorage
    @State private var onlineMode = true  // ✅ Changed from @AppStorage
    
    @State private var showingNotificationAlert = false
    @State private var showingPasswordReset = false
    
    init() {
        // Initialize with current values
        if let userId = Auth.auth().currentUser?.uid {
            _notificationsEnabled = State(initialValue: UserDefaults.standard.object(forKey: "notificationsEnabled_\(userId)") as? Bool ?? true)
            _onlineMode = State(initialValue: UserDefaults.standard.object(forKey: "onlineMode_\(userId)") as? Bool ?? true)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    // Account Section (for signed-in users)
                    if let user = authManager.user, !authManager.isAnonymous {
                        Section {
                            // Email Display
                            if let email = user.email {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Styles.Colors.accentColor)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email")
                                            .font(.headline)
                                            .foregroundColor(Styles.Colors.accentColor)
                                        
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(Styles.Colors.thirdColor)
                                    }
                                }
                                .listRowBackground(Styles.Colors.secondaryColor)
                            }
                            
                            // Reset Password Button
                            Button(action: {
                                showingPasswordReset = true
                            }) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(Styles.Colors.accentColor)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reset Password")
                                            .font(.headline)
                                            .foregroundColor(Styles.Colors.accentColor)
                                        
                                        Text("Change your account password")
                                            .font(.caption)
                                            .foregroundColor(Styles.Colors.thirdColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Styles.Colors.iconColor)
                                        .font(.caption)
                                }
                            }
                            .listRowBackground(Styles.Colors.secondaryColor)
                        } header: {
                            Label("Account", systemImage: "person.circle")
                                .foregroundColor(Styles.Colors.thirdColor)
                        }
                    }
                    
                    // Notifications Section
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(notificationsEnabled ? Styles.Colors.accentColor : Styles.Colors.iconColor)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notifications")
                                        .font(.headline)
                                        .foregroundColor(Styles.Colors.accentColor)
                                    
                                    Text("Get alerts when items expire")
                                        .font(.caption)
                                        .foregroundColor(Styles.Colors.thirdColor)
                                }
                            }
                        }
                        .toggleStyle(CustomToggleStyle())
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .onChange(of: notificationsEnabled) { oldValue, newValue in
                            handleNotificationToggle(enabled: newValue)
                        }
                    } header: {
                        Label("Notifications", systemImage: "app.badge")
                            .foregroundColor(Styles.Colors.thirdColor)
                    } footer: {
                        Text("Enable to receive expiration reminders")
                            .foregroundColor(Styles.Colors.thirdColor)
                            .font(.caption)
                    }
                    
                    // Online Mode Section
                    Section {
                        Toggle(isOn: $onlineMode) {
                            HStack {
                                Image(systemName: onlineMode ? "wifi" : "wifi.slash")
                                    .foregroundColor(onlineMode ? Styles.Colors.accentColor : Styles.Colors.iconColor)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Online Mode")
                                        .font(.headline)
                                        .foregroundColor(Styles.Colors.accentColor)
                                    
                                    Text(onlineMode ? "AI recipe generation enabled" : "Using offline mode")
                                        .font(.caption)
                                        .foregroundColor(Styles.Colors.thirdColor)
                                }
                            }
                        }
                        .toggleStyle(CustomToggleStyle())
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .onChange(of: onlineMode) { oldValue, newValue in
                            saveOnlineModeSetting(newValue)
                        }
                    } header: {
                        Label("Recipe Features", systemImage: "network")
                            .foregroundColor(Styles.Colors.thirdColor)
                    } footer: {
                        Text("Online mode enables AI-powered recipe generation. Turn off to use the app without internet features.")
                            .foregroundColor(Styles.Colors.thirdColor)
                            .font(.caption)
                    }
                    
                    // App Info Section
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            
                            Spacer()
                            
                            Text("1.0.0")
                                .foregroundColor(Styles.Colors.thirdColor)
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    } header: {
                        Label("About", systemImage: "questionmark.circle")
                            .foregroundColor(Styles.Colors.thirdColor)
                    }
                }
                .scrollContentBackground(.hidden)
                .colorScheme(.dark)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Styles.Colors.accentColor)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Notification Permission Required", isPresented: $showingNotificationAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    notificationsEnabled = false
                }
            } message: {
                Text("Please enable notifications in your device settings to receive expiration alerts.")
            }
            .fullScreenCover(isPresented: $showingPasswordReset) {
                ModernForgotPasswordView(authManager: authManager)
            }
            .onAppear {
                loadUserSettings()
            }
            .onChange(of: authManager.user?.uid) { oldValue, newValue in
                // Reload settings when user changes (e.g., switching accounts)
                loadUserSettings()
            }
        }
    }
    
    // ✅ Load user-specific settings
    private func loadUserSettings() {
        if let userId = authManager.user?.uid {
            notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled_\(userId)") as? Bool ?? true
            onlineMode = UserDefaults.standard.object(forKey: "onlineMode_\(userId)") as? Bool ?? true
            print("✅ Loaded settings for user \(userId): notifications=\(notificationsEnabled), onlineMode=\(onlineMode)")
        } else {
            notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            onlineMode = UserDefaults.standard.bool(forKey: "onlineMode")
            print("✅ Loaded global settings")
        }
    }
    
    // ✅ Save onlineMode with user-specific key
    private func saveOnlineModeSetting(_ value: Bool) {
        if let userId = authManager.user?.uid {
            UserDefaults.standard.set(value, forKey: "onlineMode_\(userId)")
            print("✅ Saved onlineMode for user \(userId): \(value)")
        } else {
            UserDefaults.standard.set(value, forKey: "onlineMode")
            print("✅ Saved global onlineMode: \(value)")
        }
        
        // ✅ Notify ContentView that settings changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    private func handleNotificationToggle(enabled: Bool) {
        // ✅ Save with user-specific key
        if let userId = authManager.user?.uid {
            UserDefaults.standard.set(enabled, forKey: "notificationsEnabled_\(userId)")
            print("✅ Saved notificationsEnabled for user \(userId): \(enabled)")
        } else {
            UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
            print("✅ Saved global notificationsEnabled: \(enabled)")
        }
        
        if enabled {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .denied {
                        showingNotificationAlert = true
                    } else if settings.authorizationStatus == .notDetermined {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                            DispatchQueue.main.async {
                                if !granted {
                                    notificationsEnabled = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UpdatedSettingsView()
        .environmentObject(AuthenticationManager())
}
