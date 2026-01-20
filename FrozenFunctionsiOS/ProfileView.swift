import SwiftUI
import UserNotifications
import CoreData
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var name = "User"
    @State private var fridgeName = "Fridge"
    @State private var selectedOption: String = "None"
    @State private var isEditing = false
    @State private var isEditingText: Bool = false
    @State private var isEditingRestrictions: Bool = false
    
    @State private var tempName = ""
    @State private var tempFridgeName = ""
    @State private var showingSettings = false
    @State private var showingUpgradeAccount = false
    @State private var showingSignInPrompt = false 
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAlert = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    if let user = authManager.user {
                        Section {
                            if authManager.isAnonymous {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Guest Mode")
                                            .font(.headline)
                                            .foregroundColor(Styles.Colors.accentColor)
                                    }
                                    
                                    Text("You're using the app as a guest. Sign in to save your data across devices!")
                                        .font(.caption)
                                        .foregroundColor(Styles.Colors.thirdColor)
                                    
                                    Button(action: {
                                        Task {
                                            await saveGuestFoodItemsBeforeSignIn()
                                            await MainActor.run {
                                                showingSignInPrompt = true
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                            Text("Sign In / Create Account")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Styles.Colors.accentColor)
                                        .foregroundColor(Styles.Colors.mainColor)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        signOut()
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                            Text("Sign Out")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.2))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Styles.Colors.secondaryColor)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Signed In")
                                            .font(.headline)
                                            .foregroundColor(Styles.Colors.accentColor)
                                    }
                                    
                                    if let email = user.email {
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundColor(Styles.Colors.thirdColor)
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Styles.Colors.secondaryColor)
                            }
                        } header: {
                            Label("Account Status", systemImage: "person.badge.key.fill")
                        }
                    }
                    
                    Section {
                        HStack(alignment: .center, spacing: 8) {
                            Label("Name:", systemImage: "person.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)
                                .frame(width: 120, alignment: .leading)
                            
                            if isEditingText {
                                TextField("Enter Name", text: $tempName)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.thirdColor)
                            } else {
                                Text(name)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 22)
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditingText {
                                tempName = name
                                isEditingText = false
                                isTextFieldFocused = false
                            }
                        }
                        HStack(alignment: .center, spacing: 8) {
                            Label("Fridge:", systemImage: "snowflake")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)
                                .frame(width: 120, alignment: .leading)
                            
                            if isEditingText {
                                TextField("Fridge Name", text: $tempFridgeName)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.thirdColor)
                            } else {
                                Text(fridgeName)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 22)
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditingText {
                                tempName = name
                                tempFridgeName = fridgeName
                                isEditingText = false
                                isTextFieldFocused = false
                            }
                        }
                        
                        Button (isEditingText ? "Done" : "Edit") {
                            if isEditingText {
                                let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedFridge = tempFridgeName.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                if !trimmedName.isEmpty {
                                    name = trimmedName
                                }
                                if !trimmedFridge.isEmpty {
                                    fridgeName = trimmedFridge
                                }
                                
                                saveProfile()
                            } else {
                                tempName = name
                                tempFridgeName = fridgeName
                            }
                            
                            isEditingText.toggle()
                            if !isEditingText {
                                isTextFieldFocused = false
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    } header: {
                        Label("Personal Information", systemImage: "person.text.rectangle.fill")
                    }
                    Section {
                        HStack(alignment: .center, spacing: 8) {
                            Label("Selected:", systemImage: "leaf.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)
                            
                            if isEditingRestrictions {
                                Picker("Restriction", selection: $selectedOption) {
                                    ForEach(Styles.Constants.dietaryRestrictions, id: \.self) { option in
                                        Text(option)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxHeight: 90)
                                .clipped()
                                .foregroundColor(Styles.Colors.thirdColor)
                                
                            } else {
                                Text(selectedOption)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .onTapGesture {
                                        isEditingRestrictions = false
                                        isEditingText = false
                                        isTextFieldFocused = false
                                    }
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                        
                        Button (isEditingRestrictions ? "Done" : "Edit") {
                            if isEditingRestrictions {
                                saveProfile()
                            }
                            isEditingRestrictions.toggle()
                            if isEditingRestrictions {
                                isTextFieldFocused = false
                                isEditingText = false
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    }
                    header: {
                        Label("Dietary Restiction", systemImage: "fork.knife")
                    }
                    Section {
                        Button(action: {
                            showingSettings = true
                        }) {
                            HStack {
                                Label("Settings", systemImage: "gearshape.fill")
                                    .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                    .font(.title3)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Styles.Colors.iconColor)
                                    .font(.caption)
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    } header: {
                        Label("App Settings", systemImage: "slider.horizontal.3")
                    }
                    if authManager.user != nil && !authManager.isAnonymous {
                        Section {
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                HStack {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                        .foregroundStyle(.red, Styles.Colors.iconColor)
                                        .font(.title3)
                                }
                            }
                            .listRowBackground(Styles.Colors.secondaryColor)
                            
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Label("Delete Account", systemImage: "trash.fill")
                                        .foregroundStyle(.red, Styles.Colors.iconColor)
                                        .font(.title3)
                                }
                            }
                            .listRowBackground(Styles.Colors.secondaryColor)
                        } header: {
                            Label("Account Actions", systemImage: "exclamationmark.triangle")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .colorScheme(.dark)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                UpdatedSettingsView()
            }
            .fullScreenCover(isPresented: $showingSignInPrompt) {
                ModernWelcomeView()
                    .environmentObject(authManager)
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutAlert, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        guard viewContext.persistentStoreCoordinator != nil else {
            print("⚠️ Core Data context not ready yet")
            return
        }
        
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            print("📊 Found \(profiles.count) profiles in Core Data")
            
            if let profile = profiles.first {
                print("📝 Loading profile: userName='\(profile.userName ?? "nil")', fridgeName='\(profile.fridgeName ?? "nil")', diet='\(profile.diet ?? "nil")'")
                name = profile.userName ?? "User"
                fridgeName = profile.fridgeName ?? "Fridge"
                selectedOption = profile.diet ?? "None"
            } else {
                print("⚠️ No profile found in Core Data - using defaults")
            }
        } catch {
            print("❌ Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard viewContext.persistentStoreCoordinator != nil else {
            print("⚠️ Core Data context not ready for saving")
            return
        }
        
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            let profile: Profile
            
            if let existingProfile = profiles.first {
                profile = existingProfile
                print("📝 Updating existing profile")
            } else {
                profile = Profile(context: viewContext)
                print("📝 Creating new profile")
            }
            
            profile.userName = name
            profile.fridgeName = fridgeName
            profile.diet = selectedOption
            
            try viewContext.save()
            print("✅ Profile saved: userName='\(name)', fridgeName='\(fridgeName)', diet='\(selectedOption)'")
            let verifyFetch: NSFetchRequest<Profile> = Profile.fetchRequest()
            let savedProfiles = try viewContext.fetch(verifyFetch)
            print("✅ Verification: \(savedProfiles.count) profiles in database after save")
            Task {
                do {
                    try await FirestoreService.shared.syncProfileToCloud(profile, context: viewContext)
                    print("✅ Profile synced to Firestore")
                } catch {
                    print("⚠️ Failed to sync profile to cloud: \(error)")
                }
            }
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    private func signOut() {
        do {
            try authManager.signOut()
            print("✅ Signed out successfully")
        } catch {
            print("❌ Sign out failed: \(error)")
        }
    }
    
    private func deleteAccount() async {
        do {
            clearAllLocalData()
            try await authManager.deleteAccount()
        } catch {
            print("❌ Delete account failed: \(error)")
        }
    }
    
    private func clearAllLocalData() {
        let context = viewContext

        let foodFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "FoodItem")
        let foodBatchDelete = NSBatchDeleteRequest(fetchRequest: foodFetch)

        let profileFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        let profileBatchDelete = NSBatchDeleteRequest(fetchRequest: profileFetch)
        
        do {
            try context.execute(foodBatchDelete)
            try context.execute(profileBatchDelete)
            try context.save()
            print("🗑️ All local data cleared")
        } catch {
            print("❌ Failed to clear local data: \(error)")
        }
    }

    private func saveGuestFoodItemsBeforeSignIn() async {
        let context = viewContext
        let fetchRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        
        await MainActor.run {
            do {
                let items = try context.fetch(fetchRequest)
                
                if items.isEmpty {
                    print("ℹ️ No guest items to save")
                    return
                }

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
    ProfileView()
        .environmentObject(AuthenticationManager())
}
