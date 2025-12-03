import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import CoreData

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAnonymous = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsProfileSetup = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var lastSyncedUserId: String? // Track which user we've synced for
    
    var userOnlineMode: Bool {
        get {
            if let userId = user?.uid {
                return UserDefaults.standard.bool(forKey: "onlineMode_\(userId)")
            }
            return UserDefaults.standard.bool(forKey: "onlineMode")
        }
        set {
            if let userId = user?.uid {
                UserDefaults.standard.set(newValue, forKey: "onlineMode_\(userId)")
            } else {
                UserDefaults.standard.set(newValue, forKey: "onlineMode")
            }
        }
    }
    
    var userNotificationsEnabled: Bool {
        get {
            if let userId = user?.uid {
                return UserDefaults.standard.bool(forKey: "notificationsEnabled_\(userId)")
            }
            return UserDefaults.standard.bool(forKey: "notificationsEnabled")
        }
        set {
            if let userId = user?.uid {
                UserDefaults.standard.set(newValue, forKey: "notificationsEnabled_\(userId)")
            } else {
                UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
            }
        }
    }
    
    init() {
        // Check if there's already a signed-in user
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAnonymous = currentUser.isAnonymous
            self.lastSyncedUserId = currentUser.uid // Mark as already synced
            print("🔄 Restored user session: \(currentUser.uid) - Anonymous: \(currentUser.isAnonymous)")
        }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                // ✅ If a real user is signing in and there was a guest before, delete guest account
                if let newUser = user, !newUser.isAnonymous {
                    if let previousUserId = self?.lastSyncedUserId,
                       previousUserId != newUser.uid,
                       UserDefaults.standard.string(forKey: "guestAccountUID") != nil {
                        // Previous session was guest, new session is real user
                        print("🗑️ Cleaning up previous guest account...")
                        UserDefaults.standard.removeObject(forKey: "guestAccountUID")
                    }
                }
                
                self?.user = user
                self?.isAnonymous = user?.isAnonymous ?? false
                print("📝 Auth state changed: \(user?.uid ?? "nil") - Anonymous: \(user?.isAnonymous ?? false)")
                
                // Only sync if this is a NEW user (not just an auth state refresh)
                if let user = user, !user.isAnonymous {
                    let userId = user.uid
                    if self?.lastSyncedUserId != userId {
                        // This is a new user signing in - sync their data
                        self?.lastSyncedUserId = userId
                        Task {
                            await self?.syncDataOnSignIn()
                        }
                    } else {
                        print("ℹ️ Same user, skipping sync to preserve local data")
                    }
                } else if user == nil {
                    // User signed out - clear the sync tracker and reset state
                    self?.lastSyncedUserId = nil
                    self?.needsProfileSetup = false  // ✅ Reset profile setup flag
                }
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Reload User
    func reloadUser() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await currentUser.reload()
        
        await MainActor.run {
            self.user = Auth.auth().currentUser
            print("✅ User reloaded - Email verified: \(currentUser.isEmailVerified)")
        }
    }
    
    private func syncDataOnSignIn() async {
        let context = PersistenceController.shared.container.viewContext
        
        // ✅ ALWAYS clear local data first when signing in as a new user
        // This prevents data bleeding between accounts
        await MainActor.run {
            print("🗑️ Clearing previous user's data...")
            let foodFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "FoodItem")
            let foodBatchDelete = NSBatchDeleteRequest(fetchRequest: foodFetch)
            
            let profileFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
            let profileBatchDelete = NSBatchDeleteRequest(fetchRequest: profileFetch)
            
            do {
                try context.execute(foodBatchDelete)
                try context.execute(profileBatchDelete)
                try context.save()
                print("✅ Previous user's data cleared")
            } catch {
                print("⚠️ Failed to clear previous data: \(error)")
            }
        }
        
        do {
            print("📥 Starting cloud sync for new user...")
            
            // Check if user has cloud data
            let hasCloudProfile = try await FirestoreService.shared.profileExists(userId: Auth.auth().currentUser?.uid ?? "")
            
            if hasCloudProfile {
                print("☁️ Cloud profile found, downloading...")
                // Download from cloud
                try await FirestoreService.shared.syncAllDataFromCloud(context: context)
                print("✅ Data synced from cloud")
            } else {
                print("📱 No cloud data found, creating default profile")
                // No cloud data - create default profile
                await createDefaultProfile()
            }
            
            // ✅ MERGE guest food items if any were saved
            await mergeGuestFoodItems()
            
        } catch {
            print("⚠️ Sync failed: \(error)")
            // Create default profile on error
            await createDefaultProfile()
            
            // ✅ Still try to merge guest items
            await mergeGuestFoodItems()
        }
    }
    
    private func createDefaultProfile(displayName: String? = nil) async {
        let context = PersistenceController.shared.container.viewContext
        
        await MainActor.run {
            let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
            
            do {
                let existingProfiles = try context.fetch(fetchRequest)
                
                if existingProfiles.isEmpty {
                    let profile = Profile(context: context)
                    profile.userName = displayName ?? "User"
                    profile.fridgeName = "My Fridge"
                    profile.diet = "None"
                    
                    try context.save()
                    print("✅ Default profile created: \(profile.userName ?? "User")")
                    
                    // ✅ Immediately sync new profile to cloud
                    Task {
                        do {
                            try await FirestoreService.shared.syncProfileToCloud(profile, context: context)
                            print("✅ Default profile synced to cloud")
                        } catch {
                            print("⚠️ Failed to sync default profile: \(error)")
                        }
                    }
                } else {
                    print("ℹ️ Profile already exists, skipping creation")
                }
            } catch {
                print("❌ Failed to create default profile: \(error)")
            }
        }
    }
    
    // MARK: - Anonymous Sign In (Reuses Existing Guest Account)
    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // ✅ Check if there's already an authenticated anonymous user in Firebase
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            print("✅ Firebase session still active - restoring guest: \(currentUser.uid)")
            
            // ✅ Verify the account actually exists by reloading user data
            do {
                try await currentUser.reload()
                print("✅ Guest account verified in Firebase")
                
                print("📦 Guest data should already be present in Core Data")
                
                await MainActor.run {
                    self.user = currentUser
                    self.isAnonymous = true
                }
                
                // ✅ Verify profile exists, create if missing
                let context = PersistenceController.shared.container.viewContext
                await MainActor.run {
                    let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
                    do {
                        let profiles = try context.fetch(fetchRequest)
                        if profiles.isEmpty {
                            print("⚠️ No profile found for guest, creating default")
                            let profile = Profile(context: context)
                            profile.userName = "User"
                            profile.fridgeName = "My Fridge"
                            profile.diet = "None"
                            try context.save()
                            print("✅ Default guest profile created")
                        } else {
                            print("✅ Guest profile exists: \(profiles.first?.userName ?? "Unknown")")
                        }
                    } catch {
                        print("❌ Error checking profile: \(error)")
                    }
                }
                
                return
            } catch {
                // ✅ Account was deleted or invalid - sign out and create new one
                print("⚠️ Guest account no longer valid (possibly deleted): \(error)")
                print("🗑️ Clearing stale session...")
                try? Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "guestAccountUID")
                // Fall through to create new account
            }
        }
        
        // ✅ If we reach here, Firebase session is gone - create new guest account
        print("🆕 Creating new guest account...")
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = true
            }
            
            // Store guest UID
            UserDefaults.standard.set(result.user.uid, forKey: "guestAccountUID")
            print("✅ New anonymous user created: \(result.user.uid)")
            
            await createDefaultProfile()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to start session: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = false
            }
            print("✅ User created: \(result.user.uid)")
            
            // ✅ Using custom verification code instead of Firebase email links
            // No need to send Firebase verification email
            
        } catch {
            await MainActor.run {
                self.errorMessage = self.friendlyErrorMessage(error)
            }
            throw error
        }
    }
    
    // MARK: - Email/Password Sign In
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = false
            }
            print("✅ User signed in: \(result.user.uid)")
            
            await syncDataOnSignIn()
        } catch {
            await MainActor.run {
                self.errorMessage = self.friendlyErrorMessage(error)
            }
            throw error
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing client ID"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = userAuthentication.user.idToken?.tokenString else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }
            
            let accessToken = userAuthentication.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let result = try await Auth.auth().signIn(with: credential)
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = false
            }
            print("✅ Google sign in successful: \(result.user.uid)")
            
            // ✅ Check if this is a NEW Google user
            let hasExistingProfile = try await checkForExistingProfile(userId: result.user.uid)
            
            if !hasExistingProfile {
                // ✅ NEW user - show profile setup screen
                await MainActor.run {
                    self.needsProfileSetup = true
                }
                print("ℹ️ New Google user - showing profile setup")
            } else {
                // Existing user - sync data normally
                await syncDataOnSignIn()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Google sign in failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // ✅ NEW: Complete profile setup (called from profile setup screen)
    func completeProfileSetup(username: String, fridgeName: String, notifications: Bool, onlineMode: Bool) async throws {
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
                    print("📝 Updating existing profile during setup")
                } else {
                    // Create new profile
                    profile = Profile(context: context)
                    print("📝 Creating new profile during setup")
                }
                
                // Set the values
                profile.userName = username
                profile.fridgeName = fridgeName
                profile.diet = "None"
                
                try context.save()
                print("✅ Profile setup saved: userName='\(username)', fridgeName='\(fridgeName)'")
                
                // Verify the save
                let verifyProfiles = try context.fetch(fetchRequest)
                print("✅ Verification: \(verifyProfiles.count) profile(s) in database")
                if let savedProfile = verifyProfiles.first {
                    print("✅ Saved profile data: userName='\(savedProfile.userName ?? "nil")', fridgeName='\(savedProfile.fridgeName ?? "nil")'")
                }
            } catch {
                print("❌ Failed to save profile: \(error)")
            }
            
            // ✅ Save preferences with user-specific keys
            if let userId = Auth.auth().currentUser?.uid {
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode_\(userId)")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled_\(userId)")
                print("✅ Preferences saved for user \(userId): onlineMode=\(onlineMode), notifications=\(notifications)")
            } else {
                print("⚠️ No user ID, saving global preferences")
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled")
            }
            
            // Mark setup as complete
            self.needsProfileSetup = false
        }
        
        // ✅ Sync to cloud
        do {
            let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
            if let profile = try context.fetch(fetchRequest).first {
                try await FirestoreService.shared.syncProfileToCloud(profile, context: context)
                print("✅ Profile synced to Firestore")
            } else {
                print("⚠️ No profile to sync to cloud")
            }
        } catch {
            print("⚠️ Failed to sync profile to cloud: \(error)")
        }
    }
    
    // ✅ Helper to check if user has existing profile in Firestore
    private func checkForExistingProfile(userId: String) async throws -> Bool {
        do {
            let profileExists = try await FirestoreService.shared.profileExists(userId: userId)
            return profileExists
        } catch {
            print("⚠️ Could not check for existing profile: \(error)")
            return false
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(to email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent to \(email)")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send password reset: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Send Verification Code (For Custom Flow)
    func sendVerificationCode(to email: String) async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        UserDefaults.standard.set(code, forKey: "verificationCode_\(email)")
        UserDefaults.standard.set(Date(), forKey: "verificationCodeTime_\(email)")
        
        print("📧 Verification code for \(email): \(code)")
        
        return code
    }
    
    // MARK: - Verify Code
    func verifyCode(_ code: String, for email: String) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: "verificationCode_\(email)"),
              let codeTime = UserDefaults.standard.object(forKey: "verificationCodeTime_\(email)") as? Date else {
            return false
        }
        
        let isExpired = Date().timeIntervalSince(codeTime) > 600
        
        if isExpired {
            UserDefaults.standard.removeObject(forKey: "verificationCode_\(email)")
            UserDefaults.standard.removeObject(forKey: "verificationCodeTime_\(email)")
            return false
        }
        
        let isValid = storedCode == code
        
        if isValid {
            UserDefaults.standard.removeObject(forKey: "verificationCode_\(email)")
            UserDefaults.standard.removeObject(forKey: "verificationCodeTime_\(email)")
        }
        
        return isValid
    }
    
    // MARK: - Convert Anonymous to Permanent Account
    func linkAnonymousAccount(email: String, password: String) async throws {
        guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No anonymous user to link"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let result = try await currentUser.link(with: credential)
            
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = false
            }
            
            print("✅ Anonymous account linked successfully!")
            
            // Clear guest UID since it's now a permanent account
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            // ✅ Using custom verification code instead of Firebase email links
            // No need to send Firebase verification email
            
            await migrateLocalDataToCloud()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Link Anonymous to Google Account
    func linkAnonymousAccountWithGoogle() async throws {
        guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No anonymous user to link"])
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing client ID"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = userAuthentication.user.idToken?.tokenString else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }
            
            let accessToken = userAuthentication.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let result = try await currentUser.link(with: credential)
            
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = false
            }
            
            print("✅ Anonymous account linked to Google!")
            
            // Clear guest UID since it's now a permanent account
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            await migrateLocalDataToCloud()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to link Google account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Sign Out (with Data Sync & Cleanup)
    func signOut() throws {
        let wasAnonymous = Auth.auth().currentUser?.isAnonymous ?? false
        let guestUID = Auth.auth().currentUser?.uid
        
        if !wasAnonymous {
            // Real account - sync to cloud, clear local data, THEN sign out
            let context = PersistenceController.shared.container.viewContext
            
            // ✅ Sync to cloud first (synchronously using semaphore)
            let syncGroup = DispatchGroup()
            syncGroup.enter()
            
            Task {
                do {
                    try await FirestoreService.shared.syncAllDataToCloud(context: context)
                    print("✅ Data synced to cloud before sign out")
                } catch {
                    print("⚠️ Failed to sync data to cloud: \(error)")
                }
                syncGroup.leave()
            }
            
            // Wait for sync to complete (with timeout)
            _ = syncGroup.wait(timeout: .now() + 5)
            
            // ✅ Clear local data BEFORE signing out
            clearAllLocalData()
            print("🗑️ Local data cleared before sign out")
            
            // Now sign out from Firebase
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                print("✅ User signed out")
            } catch {
                print("❌ Sign out error: \(error.localizedDescription)")
                throw error
            }
        } else {
            // ✅ Guest account - DON'T sign out from Firebase
            // Just reset the app state to show welcome screen
            print("✅ Guest mode - resetting to welcome screen (keeping Firebase session)")
            
            // Store the guest UID (even though we're not signing out)
            if let guestUID = guestUID {
                UserDefaults.standard.set(guestUID, forKey: "guestAccountUID")
                print("💾 Guest UID stored: \(guestUID)")
            }
            
            // ✅ Just reset the published user to nil to trigger welcome screen
            // The Firebase session remains active in the background
            DispatchQueue.main.async { [weak self] in
                self?.user = nil
                self?.isAnonymous = false
                self?.needsProfileSetup = false
                print("🔄 App state reset - welcome screen will show")
            }
            
            // DON'T clear local data - keep it for when they sign back in as guest
            print("ℹ️ Guest data preserved locally")
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // ✅ Delete user data from Firestore FIRST (before deleting auth account)
            if !user.isAnonymous {
                print("🗑️ Deleting user data from Firestore...")
                try await FirestoreService.shared.deleteAllUserData()
                print("✅ Firestore data deleted")
            }
            
            // Clear local data
            clearAllLocalData()
            
            // Clear guest UID if exists
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            // Delete Firebase Auth account
            try await user.delete()
            
            await MainActor.run {
                self.user = nil
                self.isAnonymous = false
            }
            print("✅ Account deleted successfully")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private func friendlyErrorMessage(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        switch errorCode {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Try signing in instead."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password should be at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        default:
            return error.localizedDescription
        }
    }
    
    private func migrateLocalDataToCloud() async {
        print("📤 Migrating local data to cloud...")
        let context = PersistenceController.shared.container.viewContext
        
        do {
            try await FirestoreService.shared.syncAllDataToCloud(context: context)
            print("✅ Local data migrated to cloud")
        } catch {
            print("❌ Failed to migrate data to cloud: \(error)")
        }
    }
    
    private func clearAllLocalData() {
        let context = PersistenceController.shared.container.viewContext
        
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
    
    // ✅ Merge guest food items into new account
    private func mergeGuestFoodItems() async {
        // Check if there are pending guest food items
        guard let data = UserDefaults.standard.data(forKey: "pendingGuestFoodItems"),
              let itemsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !itemsArray.isEmpty else {
            print("ℹ️ No guest food items to merge")
            return
        }
        
        print("🔄 Merging \(itemsArray.count) guest food items into new account...")
        
        let context = PersistenceController.shared.container.viewContext
        
        await MainActor.run {
            for itemData in itemsArray {
                let foodItem = FoodItem(context: context)
                foodItem.id = UUID()
                foodItem.name = itemData["name"] as? String ?? ""
                foodItem.quantity = itemData["quantity"] as? Int16 ?? 1
                foodItem.unit = itemData["unit"] as? String ?? "units"
                
                // Convert timestamp back to Date
                if let timestamp = itemData["expirationDate"] as? TimeInterval {
                    foodItem.expirationDate = Date(timeIntervalSince1970: timestamp)
                } else {
                    foodItem.expirationDate = Date()
                }
            }
            
            do {
                try context.save()
                print("✅ Successfully merged \(itemsArray.count) guest food items")
                
                // Clear the pending items
                UserDefaults.standard.removeObject(forKey: "pendingGuestFoodItems")
                
                // Sync the merged items to cloud
                Task {
                    do {
                        try await FirestoreService.shared.syncAllDataToCloud(context: context)
                        print("✅ Merged items synced to cloud")
                    } catch {
                        print("⚠️ Failed to sync merged items: \(error)")
                    }
                }
            } catch {
                print("❌ Failed to merge guest food items: \(error)")
            }
        }
    }
}
