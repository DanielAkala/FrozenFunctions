import SwiftUI
import FirebaseAuth

// MARK: - TEMPORARY DEBUG VIEW
// Add this to your project temporarily to diagnose guest mode issues
// Remove after testing!

struct DebugAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var statusMessage = "Checking..."
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Status Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Auth Status")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            InfoRow(label: "User ID", value: Auth.auth().currentUser?.uid ?? "nil")
                            InfoRow(label: "Is Anonymous", value: "\(authManager.isAnonymous)")
                            InfoRow(label: "User Object", value: authManager.user == nil ? "nil" : "exists")
                            InfoRow(label: "Guest UID Stored", value: UserDefaults.standard.string(forKey: "guestAccountUID") ?? "none")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Actions Section
                        VStack(spacing: 16) {
                            Text("Debug Actions")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            Button(action: checkStatus) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh Status")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: forceSignOut) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Force Sign Out (Firebase)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: clearUserDefaults) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Guest UID")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: nukeEverything) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                    Text("NUKE: Sign Out + Clear Everything")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Status Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Action:")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(Styles.Colors.thirdColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions:")
                                .font(.headline)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            Text("1. Check your current status")
                            Text("2. If stuck in guest mode, tap 'NUKE'")
                            Text("3. App will return to welcome screen")
                            Text("4. Remove this debug view from your code")
                        }
                        .font(.caption)
                        .foregroundColor(Styles.Colors.thirdColor)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("🐛 Debug Auth")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkStatus()
            }
            .alert("Result", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func checkStatus() {
        let uid = Auth.auth().currentUser?.uid ?? "nil"
        let isAnon = authManager.isAnonymous
        let userExists = authManager.user != nil
        let storedUID = UserDefaults.standard.string(forKey: "guestAccountUID") ?? "none"
        
        statusMessage = """
        Status Refreshed:
        - Firebase UID: \(uid)
        - Is Anonymous: \(isAnon)
        - User Object: \(userExists ? "exists" : "nil")
        - Stored Guest UID: \(storedUID)
        """
        
        print("🔍 Auth Status Check:")
        print(statusMessage)
    }
    
    private func forceSignOut() {
        do {
            try Auth.auth().signOut()
            statusMessage = "✅ Signed out from Firebase successfully"
            alertMessage = "Signed out from Firebase. App should show welcome screen."
            showAlert = true
            print("✅ Force signed out from Firebase")
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
            alertMessage = "Error signing out: \(error.localizedDescription)"
            showAlert = true
            print("❌ Force sign out error: \(error)")
        }
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "guestAccountUID")
        statusMessage = "✅ Cleared guest UID from UserDefaults"
        alertMessage = "Guest UID cleared. Try signing out now."
        showAlert = true
        print("🗑️ Cleared guest UID")
    }
    
    private func nukeEverything() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Clear guest UID
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            // Force authManager to update
            DispatchQueue.main.async {
                authManager.user = nil
                authManager.isAnonymous = false
            }
            
            statusMessage = "💥 NUKED: Signed out + Cleared everything"
            alertMessage = "Completely reset. App should show welcome screen now."
            showAlert = true
            
            print("💥 NUKE COMPLETE: Everything cleared")
            print("- Firebase: signed out")
            print("- UserDefaults: guest UID cleared")
            print("- AuthManager: reset")
        } catch {
            statusMessage = "❌ NUKE failed: \(error.localizedDescription)"
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
            print("❌ NUKE failed: \(error)")
        }
    }
}

// Helper view for displaying info
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - How to Use This Debug View
/*
 Add this to your ContentView or create a navigation link to it:
 
 // In your ContentView or ProfileView, add a debug button:
 .sheet(isPresented: $showDebugView) {
     DebugAuthView()
         .environmentObject(authManager)
 }
 
 // Add a button to show it:
 Button("🐛 Debug") {
     showDebugView = true
 }
 
 Then:
 1. Open the debug view
 2. Check your status
 3. If stuck, tap "NUKE: Sign Out + Clear Everything"
 4. App should return to welcome screen
 5. Remove this debug view after testing!
*/

#Preview {
    DebugAuthView()
        .environmentObject(AuthenticationManager())
}
