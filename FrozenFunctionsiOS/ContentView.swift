//import SwiftUI
//import CoreData
//
//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @EnvironmentObject var authManager: AuthenticationManager
//    @AppStorage("onlineMode") private var onlineMode = true
//    
//    // Fetch fridge items so the badge updates live
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
//        animation: .default
//    )
//    private var items: FetchedResults<FoodItem>
//    
//    // Count recipes whose ingredients are all present
//    private var matchingRecipeCount: Int {
//        let fridgeNames = items.compactMap { $0.name?.lowercased() }
//        return sampleRecipes.filter { recipe in
//            recipe.ingredients.allSatisfy { fridgeNames.contains($0.lowercased()) }
//        }.count
//    }
//    
//    var body: some View {
//        TabView {
//            HomeView()
//                .environment(\.managedObjectContext, viewContext)
//                .environmentObject(authManager)
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
//            
//            if onlineMode {
//                RecipeSuggestionsView()
//                    .environment(\.managedObjectContext, viewContext)
//                    .tabItem {
//                        Label("Recipes", systemImage: "book.fill")
//                    }
//                    .badge(matchingRecipeCount > 0 ? matchingRecipeCount : 0)
//            }
//            
//            ProfileView()
//                .environment(\.managedObjectContext, viewContext)
//                .environmentObject(authManager)
//                .tabItem {
//                    Label("Profile", systemImage: "person.fill")
//                }
//        }
//        .tint(Styles.Colors.accentColor)
//        .colorScheme(.dark)
//    }
//}
//
//#Preview {
//    ContentView()
//        .environmentObject(AuthenticationManager())
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}

import SwiftUI
import CoreData
import FirebaseAuth

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var onlineMode = true  // ✅ Changed from @AppStorage to @State
    
    // Fetch fridge items so the badge updates live
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<FoodItem>
    
    // Count recipes whose ingredients are all present
    private var matchingRecipeCount: Int {
        let fridgeNames = items.compactMap { $0.name?.lowercased() }
        return sampleRecipes.filter { recipe in
            recipe.ingredients.allSatisfy { fridgeNames.contains($0.lowercased()) }
        }.count
    }
    
    var body: some View {
        TabView {
            HomeView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(authManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            if onlineMode {
                RecipeSuggestionsView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .badge(matchingRecipeCount > 0 ? matchingRecipeCount : 0)
            }
            
            ProfileView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(authManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Styles.Colors.accentColor)
        .colorScheme(.dark)
        .onAppear {
            loadUserSettings()
        }
        .onChange(of: authManager.user?.uid) { oldValue, newValue in
            // ✅ Reload settings when user changes
            loadUserSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))) { _ in
            // ✅ Reload settings when they change in SettingsView
            loadUserSettings()
        }
    }
    
    // ✅ Load user-specific settings
    private func loadUserSettings() {
        if let userId = authManager.user?.uid {
            onlineMode = UserDefaults.standard.object(forKey: "onlineMode_\(userId)") as? Bool ?? true
            print("✅ Loaded settings for user \(userId): onlineMode=\(onlineMode)")
        } else {
            onlineMode = UserDefaults.standard.bool(forKey: "onlineMode")
            print("✅ Loaded global settings: onlineMode=\(onlineMode)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
