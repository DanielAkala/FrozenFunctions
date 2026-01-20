import SwiftUI
import FirebaseAuth
import CoreData

struct GuestSignInPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Styles.Colors.accentColor)
                    
                    Text("Save Your Data Forever")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Styles.Colors.accentColor)
                    
                    Text("Sign out of guest mode and create a permanent account to keep your fridge data safe across all your devices.")
                        .font(.subheadline)
                        .foregroundColor(Styles.Colors.thirdColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Styles.Colors.accentColor)
                            Text("What happens next?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Styles.Colors.accentColor)
                        }
                        
                        Text("• Your guest data will be saved")
                        Text("• You'll be signed out temporarily")
                        Text("• Create a new account or sign in")
                        Text("• Your data will be linked to your account")
                    }
                    .font(.caption)
                    .foregroundColor(Styles.Colors.thirdColor)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button(action: { handleSignOutAndContinue() }) {
                            Text("Sign Out & Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Styles.Colors.mainColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Styles.Colors.accentColor)
                                .cornerRadius(16)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Stay in Guest Mode")
                                .font(.subheadline)
                                .foregroundColor(Styles.Colors.iconColor)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Create Account")
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
            .alert("Sign Out", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSignOutAndContinue() {
        Task {
            do {
                if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                    print("🗑️ Preparing to delete anonymous Firebase account: \(currentUser.uid)")
                    await saveGuestFoodItems()
                    try await currentUser.delete()
                    print("✅ Anonymous Firebase account deleted")
                    UserDefaults.standard.removeObject(forKey: "guestAccountUID")
                    
                    await MainActor.run {
                        authManager.user = nil
                        authManager.isAnonymous = false
                        dismiss()
                    }
                } else {
                    try authManager.signOut()
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to sign out. Please try again."
                    showAlert = true
                    print("❌ Sign out error: \(error)")
                }
            }
        }
    }
    private func saveGuestFoodItems() async {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
            
            do {
                let items = try context.fetch(fetchRequest)
                let itemsData = items.map { item -> [String: Any] in
                    return [
                        "name": item.name ?? "",
                        "quantity": item.quantity,
                        "unit": item.unit ?? "units",
                        "expirationDate": (item.expirationDate ?? Date()).timeIntervalSince1970
                    ]
                }
                if let data = try? JSONSerialization.data(withJSONObject: itemsData) {
                    UserDefaults.standard.set(data, forKey: "pendingGuestFoodItems")
                    print("✅ Saved \(items.count) guest food items to transfer")
                }
            } catch {
                print("❌ Failed to save guest food items: \(error)")
            }
        }
    }
}

#Preview {
    GuestSignInPromptView()
        .environmentObject(AuthenticationManager())
}
