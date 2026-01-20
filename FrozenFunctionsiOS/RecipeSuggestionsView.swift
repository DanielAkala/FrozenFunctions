import Foundation
import SwiftUI
import CoreData

struct RecipeSuggestionsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var fetchedRecipes: [Recipe] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var lastRequestTime: Date?
    
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

                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Generating recipes...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.accentColor))
                            .foregroundColor(Styles.Colors.accentColor)
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if let error = loadError {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Oops! Something went wrong")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Text(errorMessageForUser(error))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button("Try Again") {
                                    Task {
                                        await loadRecipes()
                                    }
                                }
                                .padding(.top, 8)
                                .foregroundColor(Styles.Colors.accentColor)
                            }
                            .padding()
                            .listRowBackground(Styles.Colors.secondaryColor)
                        } else if fetchedRecipes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 50))
                                    .foregroundColor(Styles.Colors.accentColor.opacity(0.6))
                                
                                Text("Ready to cook something delicious?")
                                    .font(.headline)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .multilineTextAlignment(.center)
                                
                                Text("Tap 'Generate Recipes' to get personalized meal ideas based on your fridge contents!")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(fetchedRecipes) { recipe in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recipe.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    HStack {
                                        Label(recipe.prepTime ?? "N/A", systemImage: "clock")
                                        Spacer()
                                        Label(recipe.difficulty ?? "N/A", systemImage: "chart.bar")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(Styles.Colors.thirdColor)
                                    
                                    Text("Ingredients:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                    
                                    Text(recipe.ingredients.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("Instructions:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                    
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
            }
            .navigationTitle("Meal Ideas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate Recipes") {
                        Task {
                            await loadRecipes()
                        }
                    }
                    .foregroundColor(canMakeRequest() ? Styles.Colors.accentColor : Styles.Colors.accentColor.opacity(0.5))
                    .disabled(!canMakeRequest())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func canMakeRequest() -> Bool {
        if isLoading { return false }
        
        guard let lastTime = lastRequestTime else { return true }
        return Date().timeIntervalSince(lastTime) >= 5
    }

    private func errorMessageForUser(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("503") || errorString.contains("overloaded") || errorString.contains("unavailable") {
            return "The AI service is busy right now. Please try again in a moment."
        } else if errorString.contains("429") || errorString.contains("quota") || errorString.contains("rate limit") {
            return "Too many requests. Please wait a moment before trying again."
        } else if errorString.contains("400") || errorString.contains("invalid") {
            return "There was a problem with your request. Please make sure you have items in your fridge."
        } else if errorString.contains("network") || errorString.contains("internet") {
            return "Please check your internet connection and try again."
        } else {
            return "Unable to generate recipes. Please try again later."
        }
    }
    
    private func loadRecipes() async {
        guard !fridgeItems.isEmpty else {
            await MainActor.run {
                fetchedRecipes = []
                loadError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your fridge is empty! Add items first."])
            }
            return
        }

        if !canMakeRequest() { return }
        
        await MainActor.run {
            isLoading = true
            loadError = nil
            lastRequestTime = Date()
        }

        let allFridgeNames = fridgeItems.compactMap { $0.name }
        let fridgeNames = Array(allFridgeNames.prefix(15))
        let diet = profiles.first?.diet ?? "None"

        do {
            let recipes = try await recipeService.fetchRecipes(for: fridgeNames, diet: diet)
            await MainActor.run {
                self.fetchedRecipes = recipes
                self.isLoading = false
            }
        } catch {
            print("🔴 Error fetching recipes: \(error.localizedDescription)")
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }
}
