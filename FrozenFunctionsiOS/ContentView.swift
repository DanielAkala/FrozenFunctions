import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

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
                .tabItem { Label("Home", systemImage: "house.fill") }

            RecipeSuggestionsView()
                .tabItem { Label("Recipes", systemImage: "book.fill") }
                // Hide badge when 0 by passing nil
                .tabBadge(matchingRecipeCount)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}
#Preview {
    ContentView()
}
