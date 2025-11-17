import Foundation
import SwiftUI
import CoreData

struct RecipeSuggestionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // State variables to hold API data and manage UI state
    @State private var fetchedRecipes: [Recipe] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let recipeService = RecipeService()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
        animation: .default)
    private var fridgeItems: FetchedResults<FoodItem>
    
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var profiles: FetchedResults<Profile>

    var body: some View {
        NavigationStack {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()

                List {
                    if isLoading {
                        ProgressView("Generating recipes...")
                            .foregroundColor(.white)
                            .listRowBackground(Styles.Colors.secondaryColor)
                    } else if let error = loadError {
                        // Display error message if API call failed
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .listRowBackground(Styles.Colors.secondaryColor)
                    } else if fetchedRecipes.isEmpty {
                        Text("Your fridge items are ready! Tap 'Generate Recipes' to get ideas 💡")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .listRowBackground(Styles.Colors.secondaryColor)
                    } else {
                        // Display the fetched recipes
                        ForEach(fetchedRecipes) { recipe in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                // Display new API properties
                                Text("Prep Time: \(recipe.prepTime ?? "N/A") | Difficulty: \(recipe.difficulty ?? "N/A")")
                                    .font(.subheadline)
                                    .foregroundColor(Styles.Colors.thirdColor)
                                
                                Text("Ingredients: \(recipe.ingredients.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))

                                Text(recipe.instructions)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Styles.Colors.secondaryColor)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Meal Ideas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Button to trigger the API call
                    Button("Generate Recipes") {
                        Task {
                            await loadRecipes()
                        }
                    }
                    .foregroundColor(Styles.Colors.accentColor)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func loadRecipes() async {
        guard !fridgeItems.isEmpty else {
            fetchedRecipes = []
            loadError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your fridge is empty! Add items first."])
            return
        }
        
        isLoading = true
        loadError = nil
        
        // 1. Prepare API parameters
        let fridgeNames = fridgeItems.compactMap { $0.name }
        let diet = profiles.first?.diet ?? "None"
        
        // 2. Call the API asynchronously
        do {
            let recipes = try await recipeService.fetchRecipes(for: fridgeNames, diet: diet)
            // Update UI on the main actor
            await MainActor.run {
                self.fetchedRecipes = recipes
                self.isLoading = false
            }
        } catch {
            print("Error fetching recipes: \(error.localizedDescription)")
            // Update UI on the main actor
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }
}
