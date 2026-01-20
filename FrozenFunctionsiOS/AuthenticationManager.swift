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
    private var lastSyncedUserId: String? 
    
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
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAnonymous = currentUser.isAnonymous
            self.lastSyncedUserId = currentUser.uid 
            print("🔄 Restored user session: \(currentUser.uid) - Anonymous: \(currentUser.isAnonymous)")
        }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let newUser = user, !newUser.isAnonymous {
                    if let previousUserId = self?.lastSyncedUserId,
                       previousUserId != newUser.uid,
                       UserDefaults.standard.string(forKey: "guestAccountUID") != nil {
                        print("🗑️ Cleaning up previous guest account...")
                        UserDefaults.standard.removeObject(forKey: "guestAccountUID")
                    }
                }
                
                self?.user = user
                self?.isAnonymous = user?.isAnonymous ?? false
                print("📝 Auth state changed: \(user?.uid ?? "nil") - Anonymous: \(user?.isAnonymous ?? false)")
                
                if let user = user, !user.isAnonymous {
                    let userId = user.uid
                    if self?.lastSyncedUserId != userId {
                        self?.lastSyncedUserId = userId
                        Task {
                            await self?.syncDataOnSignIn()
                        }
                    } else {
                        print("ℹ️ Same user, skipping sync to preserve local data")
                    }
                } else if user == nil {
                    self?.lastSyncedUserId = nil
                    self?.needsProfileSetup = false 
                }
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
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
            
            let hasCloudProfile = try await FirestoreService.shared.profileExists(userId: Auth.auth().currentUser?.uid ?? "")
            
            if hasCloudProfile {
                print("☁️ Cloud profile found, downloading...")
                try await FirestoreService.shared.syncAllDataFromCloud(context: context)
                print("✅ Data synced from cloud")
            } else {
                print("📱 No cloud data found, creating default profile")
                await createDefaultProfile()
            }
            
            await mergeGuestFoodItems()
            
        } catch {
            print("⚠️ Sync failed: \(error)")
            await createDefaultProfile()
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
    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            print("✅ Firebase session still active - restoring guest: \(currentUser.uid)")
            do {
                try await currentUser.reload()
                print("✅ Guest account verified in Firebase")
                
                print("📦 Guest data should already be present in Core Data")
                
                await MainActor.run {
                    self.user = currentUser
                    self.isAnonymous = true
                }
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
                print("⚠️ Guest account no longer valid (possibly deleted): \(error)")
                print("🗑️ Clearing stale session...")
                try? Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            }
        }
        print("🆕 Creating new guest account...")
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.user = result.user
                self.isAnonymous = true
            }
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
        } catch {
            await MainActor.run {
                self.errorMessage = self.friendlyErrorMessage(error)
            }
            throw error
        }
    }
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
            let hasExistingProfile = try await checkForExistingProfile(userId: result.user.uid)
            
            if !hasExistingProfile {
                await MainActor.run {
                    self.needsProfileSetup = true
                }
                print("ℹ️ New Google user - showing profile setup")
            } else {
                await syncDataOnSignIn()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Google sign in failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    func completeProfileSetup(username: String, fridgeName: String, notifications: Bool, onlineMode: Bool) async throws {
        let context = PersistenceController.shared.container.viewContext
        
        await MainActor.run {
            let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
            
            do {
                let existingProfiles = try context.fetch(fetchRequest)
                let profile: Profile
                
                if let existingProfile = existingProfiles.first {
                    profile = existingProfile
                    print("📝 Updating existing profile during setup")
                } else {
                    profile = Profile(context: context)
                    print("📝 Creating new profile during setup")
                }
                profile.userName = username
                profile.fridgeName = fridgeName
                profile.diet = "None"
                
                try context.save()
                print("✅ Profile setup saved: userName='\(username)', fridgeName='\(fridgeName)'")
                let verifyProfiles = try context.fetch(fetchRequest)
                print("✅ Verification: \(verifyProfiles.count) profile(s) in database")
                if let savedProfile = verifyProfiles.first {
                    print("✅ Saved profile data: userName='\(savedProfile.userName ?? "nil")', fridgeName='\(savedProfile.fridgeName ?? "nil")'")
                }
            } catch {
                print("❌ Failed to save profile: \(error)")
            }
            if let userId = Auth.auth().currentUser?.uid {
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode_\(userId)")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled_\(userId)")
                print("✅ Preferences saved for user \(userId): onlineMode=\(onlineMode), notifications=\(notifications)")
            } else {
                print("⚠️ No user ID, saving global preferences")
                UserDefaults.standard.set(onlineMode, forKey: "onlineMode")
                UserDefaults.standard.set(notifications, forKey: "notificationsEnabled")
            }
            self.needsProfileSetup = false
        }
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
    private func checkForExistingProfile(userId: String) async throws -> Bool {
        do {
            let profileExists = try await FirestoreService.shared.profileExists(userId: userId)
            return profileExists
        } catch {
            print("⚠️ Could not check for existing profile: \(error)")
            return false
        }
    }
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
    func sendVerificationCode(to email: String) async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        UserDefaults.standard.set(code, forKey: "verificationCode_\(email)")
        UserDefaults.standard.set(Date(), forKey: "verificationCodeTime_\(email)")
        
        print("📧 Verification code for \(email): \(code)")
        
        return code
    }
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

            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            await migrateLocalDataToCloud()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save account: \(error.localizedDescription)"
            }
            throw error
        }
    }
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
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
            
            await migrateLocalDataToCloud()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to link Google account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    func signOut() throws {
        let wasAnonymous = Auth.auth().currentUser?.isAnonymous ?? false
        let guestUID = Auth.auth().currentUser?.uid
        
        if !wasAnonymous {
            let context = PersistenceController.shared.container.viewContext
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
            _ = syncGroup.wait(timeout: .now() + 5)
            clearAllLocalData()
            print("🗑️ Local data cleared before sign out")
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                print("✅ User signed out")
            } catch {
                print("❌ Sign out error: \(error.localizedDescription)")
                throw error
            }
        } else {
            print("✅ Guest mode - resetting to welcome screen (keeping Firebase session)")
            if let guestUID = guestUID {
                UserDefaults.standard.set(guestUID, forKey: "guestAccountUID")
                print("💾 Guest UID stored: \(guestUID)")
            }
            DispatchQueue.main.async { [weak self] in
                self?.user = nil
                self?.isAnonymous = false
                self?.needsProfileSetup = false
                print("🔄 App state reset - welcome screen will show")
            }
            print("ℹ️ Guest data preserved locally")
        }
    }
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if !user.isAnonymous {
                print("🗑️ Deleting user data from Firestore...")
                try await FirestoreService.shared.deleteAllUserData()
                print("✅ Firestore data deleted")
            }
            clearAllLocalData()
            UserDefaults.standard.removeObject(forKey: "guestAccountUID")
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
    private func mergeGuestFoodItems() async {
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
                if let timestamp = itemData["expirationDate"] as? TimeInterval {
                    foodItem.expirationDate = Date(timeIntervalSince1970: timestamp)
                } else {
                    foodItem.expirationDate = Date()
                }
            }
            
            do {
                try context.save()
                print("✅ Successfully merged \(itemsArray.count) guest food items")
                UserDefaults.standard.removeObject(forKey: "pendingGuestFoodItems")
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
