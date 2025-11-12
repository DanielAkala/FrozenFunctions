import Foundation
import SwiftUI
import CoreData

struct RecipeSuggestionsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<FoodItem>

    private func findMatchingRecipes(from fridgeItems: [FoodItem]) -> [Recipe] {
        let fridgeNames = fridgeItems.compactMap { $0.name?.lowercased() }

        return sampleRecipes.filter { recipe in
            recipe.ingredients.allSatisfy { fridgeNames.contains($0.lowercased()) }
        }
    }

    var body: some View {
            let matchingRecipes = findMatchingRecipes(from: Array(items))

            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()

                List {
                    if matchingRecipes.isEmpty {
                        Text("No matching recipes found 🍽️")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .listRowBackground(Styles.Colors.secondaryColor)
                    } else {
                        ForEach(matchingRecipes) { recipe in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .foregroundColor(.white)

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
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

