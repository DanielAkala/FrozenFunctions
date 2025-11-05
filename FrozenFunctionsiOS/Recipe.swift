//
//  Recipe.swift
//  FrozenFunctionsiOS
//
//  Created by csuftitan on 11/3/25.
//

import Foundation

struct Recipe: Identifiable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let instructions: String
}

let sampleRecipes: [Recipe] = [
    Recipe(
        name: "Grilled Cheese Sandwich",
        ingredients: ["bread", "cheese", "butter"],
        instructions: "Butter two slices of bread, place cheese between them, and grill on both sides until golden brown."
    ),
    Recipe(
        name: "Fruit Salad",
        ingredients: ["apple", "banana", "orange"],
        instructions: "Chop all fruits, mix in a bowl, and chill before serving."
    ),
    Recipe(
        name: "Omelette",
        ingredients: ["egg", "milk", "salt"],
        instructions: "Whisk eggs with milk and salt, pour into a pan, and cook until fluffy."
    ),
    Recipe(
        name: "Pasta Alfredo",
        ingredients: ["pasta", "milk", "cheese", "butter"],
        instructions: "Boil pasta. In a pan, melt butter, add milk and cheese to create sauce, then mix with pasta."
    ),
    Recipe(
        name: "Avocado Toast",
        ingredients: ["bread", "avocado", "salt"],
        instructions: "Toast the bread, mash the avocado, spread it on top, and sprinkle with salt."
    ),
    Recipe(
        name: "Tomato Soup",
        ingredients: ["tomato", "onion", "salt"],
        instructions: "Cook chopped tomatoes and onions, blend until smooth, and season with salt."
    ),
    Recipe(
        name: "Peanut Butter Smoothie",
        ingredients: ["milk", "banana", "peanut butter"],
        instructions: "Blend banana, milk, and peanut butter until creamy."
    ),
    Recipe(
        name: "Chicken Stir Fry",
        ingredients: ["chicken", "rice", "onion", "soy sauce"],
        instructions: "Cook chicken and onions in a pan, add soy sauce, and serve with rice."
    ),
    Recipe(
        name: "Veggie Omelette",
        ingredients: ["egg", "bell pepper", "onion", "salt"],
        instructions: "Whisk eggs, add chopped peppers and onions, season, and cook until done."
    ),
    Recipe(
        name: "Pancakes",
        ingredients: ["flour", "milk", "egg", "butter"],
        instructions: "Mix flour, milk, and eggs, then cook on a buttered skillet until golden on both sides."
    )
]
