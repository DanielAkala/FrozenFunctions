import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false
    @State private var showingProfile = false
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            RecipeSuggestionsView()
                .tabItem { Label("Recipes", systemImage: "book.fill") }
                // Hide badge when 0 by passing nil
                //.tabBadge(matchingRecipeCount)
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
