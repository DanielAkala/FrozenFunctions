import Foundation

// Sample recipes for the badge count in ContentView
// These are simple recipes that match against fridge items
struct SimpleRecipe: Identifiable {
    let id = UUID()
    let name: String
    let ingredients: [String]
}

let sampleRecipes: [SimpleRecipe] = [
    SimpleRecipe(
        name: "Grilled Cheese Sandwich",
        ingredients: ["bread", "cheese", "butter"]
    ),
    SimpleRecipe(
        name: "Fruit Salad",
        ingredients: ["apple", "banana", "orange"]
    ),
    SimpleRecipe(
        name: "Omelette",
        ingredients: ["egg", "milk", "salt"]
    ),
    SimpleRecipe(
        name: "Pasta Alfredo",
        ingredients: ["pasta", "milk", "cheese", "butter"]
    ),
    SimpleRecipe(
        name: "Avocado Toast",
        ingredients: ["bread", "avocado", "salt"]
    ),
    SimpleRecipe(
        name: "Tomato Soup",
        ingredients: ["tomato", "onion", "salt"]
    ),
    SimpleRecipe(
        name: "Peanut Butter Smoothie",
        ingredients: ["milk", "banana", "peanut butter"]
    ),
    SimpleRecipe(
        name: "Chicken Stir Fry",
        ingredients: ["chicken", "rice", "onion", "soy sauce"]
    ),
    SimpleRecipe(
        name: "Veggie Omelette",
        ingredients: ["egg", "bell pepper", "onion", "salt"]
    ),
    SimpleRecipe(
        name: "Pancakes",
        ingredients: ["flour", "milk", "egg", "butter"]
    )
]
