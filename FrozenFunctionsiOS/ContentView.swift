import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false
    @State private var showingProfile = false
    
    // Fetch fridge items so the badge updates live (this part is kept)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<FoodItem>
    
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            RecipeSuggestionsView()
                .tabItem { Label("Recipes", systemImage: "book.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Styles.Colors.accentColor)
        .colorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
