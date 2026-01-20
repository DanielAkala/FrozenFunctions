import SwiftUI
import CoreData
import FirebaseAuth

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var onlineMode = true 
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<FoodItem>
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
            loadUserSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))) { _ in
            loadUserSettings()
        }
    }
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
