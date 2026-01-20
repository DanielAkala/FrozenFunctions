import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData

struct FirestoreFoodItem: Codable {
    var id: String
    var name: String
    var quantity: Int
    var unit: String
    var expirationDate: Date
    var userId: String
    
    init(from foodItem: FoodItem, userId: String) {
        self.id = foodItem.id?.uuidString ?? UUID().uuidString
        self.name = foodItem.name ?? ""
        self.quantity = Int(foodItem.quantity)
        self.unit = foodItem.unit ?? "Items"
        self.expirationDate = foodItem.expirationDate ?? Date()
        self.userId = userId
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "quantity": quantity,
            "unit": unit,
            "expirationDate": Timestamp(date: expirationDate),
            "userId": userId
        ]
    }
    
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let name = document["name"] as? String,
              let quantity = document["quantity"] as? Int,
              let unit = document["unit"] as? String,
              let timestamp = document["expirationDate"] as? Timestamp,
              let userId = document["userId"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = timestamp.dateValue()
        self.userId = userId
    }
}

struct FirestoreProfile: Codable {
    var userId: String
    var userName: String
    var fridgeName: String
    var diet: String
    
    init(from profile: Profile, userId: String) {
        self.userId = userId
        self.userName = profile.userName ?? "User"
        self.fridgeName = profile.fridgeName ?? "Fridge"
        self.diet = profile.diet ?? "None"
    }
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "userName": userName,
            "fridgeName": fridgeName,
            "diet": diet
        ]
    }
    
    init?(document: [String: Any]) {
        guard let userId = document["userId"] as? String,
              let userName = document["userName"] as? String,
              let fridgeName = document["fridgeName"] as? String,
              let diet = document["diet"] as? String else {
            return nil
        }
        
        self.userId = userId
        self.userName = userName
        self.fridgeName = fridgeName
        self.diet = diet
    }
}

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func syncFoodItemsToCloud(context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Cannot sync: No authenticated user")
            return
        }
        
        let fetchRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            
            for item in items {
                let firestoreItem = FirestoreFoodItem(from: item, userId: userId)
                try await db.collection("foodItems")
                    .document(firestoreItem.id)
                    .setData(firestoreItem.dictionary, merge: true)
            }
            
            print("✅ Synced \(items.count) food items to Firestore")
        } catch {
            print("❌ Error syncing food items: \(error)")
            throw error
        }
    }
    
    func syncFoodItemsFromCloud(context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Cannot sync: No authenticated user")
            return
        }
        
        do {
            let snapshot = try await db.collection("foodItems")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            await MainActor.run {
                let fetchRequest: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
                let existingItems = (try? context.fetch(fetchRequest)) ?? []
                let existingIDs = Set(existingItems.compactMap { $0.id?.uuidString })

                for document in snapshot.documents {
                    if let firestoreItem = FirestoreFoodItem(document: document.data()) {
                        if existingIDs.contains(firestoreItem.id) {
                            continue
                        }
                        
                        let foodItem = FoodItem(context: context)
                        foodItem.id = UUID(uuidString: firestoreItem.id) ?? UUID()
                        foodItem.name = firestoreItem.name
                        foodItem.quantity = Int16(firestoreItem.quantity)
                        foodItem.unit = firestoreItem.unit
                        foodItem.expirationDate = firestoreItem.expirationDate
                    }
                }
                
                do {
                    try context.save()
                    print("✅ Downloaded \(snapshot.documents.count) food items from Firestore")
                } catch {
                    print("❌ Error saving synced items: \(error)")
                }
            }
        } catch {
            print("❌ Error downloading food items: \(error)")
            throw error
        }
    }
    
    func saveFoodItem(_ item: FoodItem, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Skipping cloud sync: Guest mode")
            return
        }
        
        let firestoreItem = FirestoreFoodItem(from: item, userId: userId)
        try await db.collection("foodItems")
            .document(firestoreItem.id)
            .setData(firestoreItem.dictionary, merge: true)
        
        print("✅ Saved food item to Firestore: \(firestoreItem.name)")
    }
    
    func deleteFoodItem(id: String) async throws {
        guard Auth.auth().currentUser != nil,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Skipping cloud deletion: Guest mode")
            return
        }
        
        try await db.collection("foodItems").document(id).delete()
        print("✅ Deleted food item from Firestore")
    }

    func syncProfileToCloud(_ profile: Profile, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Cannot sync profile: No authenticated user")
            return
        }
        
        let firestoreProfile = FirestoreProfile(from: profile, userId: userId)
        try await db.collection("profiles")
            .document(userId)
            .setData(firestoreProfile.dictionary, merge: true)
        
        print("✅ Synced profile to Firestore")
    }
    
    func syncProfileFromCloud(context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            print("⚠️ Cannot sync profile: No authenticated user")
            return
        }
        
        do {
            let document = try await db.collection("profiles").document(userId).getDocument()
            
            if let data = document.data(),
               let firestoreProfile = FirestoreProfile(document: data) {
                
                await MainActor.run {
                    let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
                    
                    do {
                        let profiles = try context.fetch(fetchRequest)
                        let profile = profiles.first ?? Profile(context: context)

                        if firestoreProfile.userName != "User" {
                            profile.userName = firestoreProfile.userName
                        }
                        if firestoreProfile.fridgeName != "My Fridge" && firestoreProfile.fridgeName != "Fridge" {
                            profile.fridgeName = firestoreProfile.fridgeName
                        }
                        profile.diet = firestoreProfile.diet
                        
                        try context.save()
                        print("✅ Downloaded profile from Firestore")
                    } catch {
                        print("❌ Error saving profile: \(error)")
                    }
                }
            } else {
                print("ℹ️ No profile found in cloud, keeping local")
            }
        } catch {
            print("❌ Error downloading profile: \(error)")
            throw error
        }
    }
    
    func syncAllDataFromCloud(context: NSManagedObjectContext) async throws {
        print("📥 Starting full sync from cloud...")
        try await syncProfileFromCloud(context: context)
        try await syncFoodItemsFromCloud(context: context)
        print("✅ Full sync completed")
    }
    
    func syncAllDataToCloud(context: NSManagedObjectContext) async throws {
        print("📤 Starting full sync to cloud...")
        
        let profileFetch: NSFetchRequest<Profile> = Profile.fetchRequest()
        if let profile = try context.fetch(profileFetch).first {
            try await syncProfileToCloud(profile, context: context)
        }
        
        try await syncFoodItemsToCloud(context: context)
        
        print("✅ Full sync to cloud completed")
    }
    
    func deleteAllUserData() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID for deletion")
            return
        }
        
        print("🗑️ Deleting all data for user: \(userId)")
        
        let foodSnapshot = try await db.collection("foodItems")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        print("📦 Found \(foodSnapshot.documents.count) food items to delete")
        
        for document in foodSnapshot.documents {
            try await document.reference.delete()
        }
        
        try await db.collection("profiles").document(userId).delete()
        
        print("✅ All user data deleted from Firestore")
    }
    
    func profileExists(userId: String) async throws -> Bool {
        do {
            let document = try await db.collection("profiles").document(userId).getDocument()
            let exists = document.exists
            print(exists ? "✅ Profile exists for user: \(userId)" : "ℹ️ No profile found for user: \(userId)")
            return exists
        } catch {
            print("❌ Error checking profile existence: \(error)")
            throw error
        }
    }
}
